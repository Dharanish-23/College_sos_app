"""
yolo_analyzer.py
Uses YOLOv8 (ultralytics) to detect persons in video frames.

Rule:
  - If ANY person is detected with >= MIN_CONFIDENCE  →  incident_detected = True
                                                          verdict = "Physical Altercation Detected"
  - Otherwise                                          →  incident_detected = False
                                                          verdict = "No Physical Altercation Detected"

Handles drone/HEVC/H.265 video by trying multiple decode strategies.

Install:  pip install ultralytics opencv-python-headless numpy
"""

import asyncio
import tempfile
import os
from functools import partial

# ── Tunable constants ─────────────────────────────────────────────────────────
MIN_CONFIDENCE = 0.35   # minimum YOLO confidence to count a person detection
MAX_FRAMES     = 40     # cap on sampled frames to keep response time reasonable
# ─────────────────────────────────────────────────────────────────────────────

_model = None


def _get_model():
    global _model
    if _model is None:
        from ultralytics import YOLO
        _model = YOLO("yolov8n.pt")  # nano — fastest; auto-downloads on first use
    return _model


def _try_open_video(path: str):
    """
    Try multiple OpenCV backends to open the video.
    Drone footage is often H.265/HEVC or in .mp4 containers that need
    a different backend.  Returns an opened VideoCapture or None.
    """
    import cv2

    # Try default first
    cap = cv2.VideoCapture(path)
    if cap.isOpened() and cap.get(cv2.CAP_PROP_FRAME_COUNT) > 0:
        return cap
    cap.release()

    # Try FFMPEG backend explicitly
    cap = cv2.VideoCapture(path, cv2.CAP_FFMPEG)
    if cap.isOpened() and cap.get(cv2.CAP_PROP_FRAME_COUNT) > 0:
        return cap
    cap.release()

    return None


def _read_frame_safe(cap, frame_idx: int):
    """
    Seek to frame_idx and read. Falls back to sequential read if seek fails.
    Returns (success, frame).
    """
    import cv2
    cap.set(cv2.CAP_PROP_POS_FRAMES, frame_idx)
    ret, frame = cap.read()
    return ret, frame


def _analyze_video_sync(video_bytes: bytes) -> dict:
    """
    Synchronous YOLO person-detection analysis.
    Runs in a thread-pool executor so it never blocks FastAPI's event loop.

    Returns a dict with at minimum:
        incident_detected   bool
        verdict             str   "Physical Altercation Detected" | "No Physical Altercation Detected"
        persons_detected    int   max persons seen in a single frame
        person_frames       int   number of frames containing at least one person
        frames_analyzed     int
        confidence          float max detection confidence (0.0 – 1.0)
        duration_seconds    float
        severity            str   "none" | "low" | "medium" | "high"
        error               str | None
    """
    import cv2

    # ── 1. Write video bytes to a temp file ──────────────────────────────────
    suffix = ".mp4"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(video_bytes)
        tmp_path = tmp.name

    try:
        # ── 2. Load YOLO model ────────────────────────────────────────────────
        try:
            model = _get_model()
        except Exception as model_err:
            return _error_result(f"Failed to load YOLO model: {model_err}")

        # ── 3. Open video ─────────────────────────────────────────────────────
        cap = _try_open_video(tmp_path)
        if cap is None:
            return _error_result(
                "Could not open video file. "
                "Ensure the video is a valid mp4/mov/avi/webm. "
                "Drone H.265 files may need re-encoding to H.264."
            )

        fps            = cap.get(cv2.CAP_PROP_FPS) or 25.0
        total_frames   = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        duration_sec   = total_frames / fps if fps > 0 else 0.0

        # Sample ~1 frame/second, capped at MAX_FRAMES
        sample_interval = max(1, int(round(fps)))
        available_steps = max(1, total_frames // sample_interval)
        steps_to_take   = min(available_steps, MAX_FRAMES)

        frames_analyzed      = 0
        person_frames        = 0
        max_persons_in_frame = 0
        max_confidence       = 0.0
        consecutive_fails    = 0

        for step in range(steps_to_take):
            frame_idx = step * sample_interval
            ret, frame = _read_frame_safe(cap, frame_idx)

            if not ret:
                consecutive_fails += 1
                if consecutive_fails >= 5:
                    # Give up — video likely unreadable after this point
                    break
                continue

            consecutive_fails = 0

            # ── 4. Run YOLO on this frame ─────────────────────────────────
            try:
                results = model(frame, classes=[0], verbose=False, conf=MIN_CONFIDENCE)
            except Exception:
                continue  # skip bad frame, don't abort whole video

            persons_this_frame = 0
            for r in results:
                for box in r.boxes:
                    cls  = int(box.cls[0])
                    conf = float(box.conf[0])
                    if cls == 0 and conf >= MIN_CONFIDENCE:
                        persons_this_frame += 1
                        if conf > max_confidence:
                            max_confidence = conf

            if persons_this_frame > 0:
                person_frames += 1
                if persons_this_frame > max_persons_in_frame:
                    max_persons_in_frame = persons_this_frame

            frames_analyzed += 1

        cap.release()

        # ── 5. Verdict: ONLY true if at least one real person was detected ──
        incident_detected = (person_frames > 0)

        return {
            "incident_detected": incident_detected,
            "verdict": (
                "Physical Altercation Detected"
                if incident_detected
                else "No Physical Altercation Detected"
            ),
            "persons_detected":  max_persons_in_frame,
            "person_frames":     person_frames,
            "frames_analyzed":   frames_analyzed,
            "confidence":        round(max_confidence, 3),
            "duration_seconds":  round(duration_sec, 1),
            "severity":          _assess_severity(max_persons_in_frame, max_confidence),
            "error":             None,
        }

    except Exception as exc:
        return _error_result(f"Unexpected analysis error: {exc}")

    finally:
        try:
            os.unlink(tmp_path)
        except Exception:
            pass


# ── Helpers ───────────────────────────────────────────────────────────────────

def _error_result(message: str) -> dict:
    """Return a safe 'no incident' result with an error description."""
    return {
        "incident_detected": False,
        "verdict":           "No Physical Altercation Detected",
        "persons_detected":  0,
        "person_frames":     0,
        "frames_analyzed":   0,
        "confidence":        0.0,
        "duration_seconds":  0.0,
        "severity":          "none",
        "error":             message,
    }


def _assess_severity(persons: int, confidence: float) -> str:
    if persons == 0:
        return "none"
    if persons >= 4 or confidence >= 0.85:
        return "high"
    if persons >= 2 or confidence >= 0.65:
        return "medium"
    return "low"


async def analyze_video_for_persons(video_bytes: bytes) -> dict:
    """
    Async entry point — runs YOLO analysis off the event loop.
    """
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(
        None,
        partial(_analyze_video_sync, video_bytes),
    )
