"""
upload_routes.py
Handles video/image uploads → Cloudinary CDN.
Stores Cloudinary URLs + metadata in MongoDB.
"""
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Form
from auth import get_current_student
from database import get_db
from cloudinary_service import upload_sos_video, upload_complaint_image, upload_complaint_video
from bson import ObjectId
from datetime import datetime

router = APIRouter(prefix="/upload", tags=["Upload"])

# ── Size limits ────────────────────────────────────────────────────────────────
MAX_VIDEO_MB = 200
MAX_IMAGE_MB = 10
MAX_VIDEO_BYTES = MAX_VIDEO_MB * 1024 * 1024
MAX_IMAGE_BYTES = MAX_IMAGE_MB * 1024 * 1024

ALLOWED_VIDEO_TYPES = {
    "video/mp4", "video/quicktime", "video/x-msvideo",
    "video/webm", "video/3gpp", "video/mpeg",
}
ALLOWED_IMAGE_TYPES = {
    "image/jpeg", "image/jpg", "image/png",
    "image/gif", "image/webp",
}


# ── POST /upload/sos-video ────────────────────────────────────────────────────

@router.post("/sos-video")
async def upload_sos_video_endpoint(
    file: UploadFile = File(...),
    sos_id: str = Form(...),
    current_user=Depends(get_current_student),
):
    """
    Upload SOS evidence video → Cloudinary.
    Attaches the returned URL + metadata to the SOS record in MongoDB.
    """
    content_type = (file.content_type or "").lower()
    if content_type not in ALLOWED_VIDEO_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type '{content_type}'. Allowed: mp4, mov, avi, webm, 3gp."
        )

    file_bytes = await file.read()
    if len(file_bytes) > MAX_VIDEO_BYTES:
        raise HTTPException(status_code=413, detail=f"Video too large. Max {MAX_VIDEO_MB} MB.")
    if len(file_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty file.")

    # Upload to Cloudinary
    try:
        result = await upload_sos_video(file_bytes, file.filename or "sos_video.mp4")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Cloudinary upload failed: {str(e)}")

    # Validate SOS ID
    try:
        oid = ObjectId(sos_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid SOS ID format.")

    # Update MongoDB record
    db = get_db()
    now = datetime.utcnow()
    await db.sos_requests.update_one(
        {"_id": oid, "student_id": current_user["_id"]},
        {
            "$set": {
                "has_video": True,
                "video_url": result["url"],
                "video_thumbnail_url": result.get("thumbnail_url", ""),
                "video_public_id": result.get("public_id", ""),
                "video_duration": result.get("duration"),
                "video_size_bytes": result.get("bytes"),
                "updated_at": now,
            }
        },
    )

    return {
        "success": True,
        "url": result["url"],
        "thumbnail_url": result.get("thumbnail_url", ""),
        "public_id": result.get("public_id", ""),
        "duration": result.get("duration"),
        "sos_id": sos_id,
        "message": "Video uploaded to Cloudinary successfully.",
    }


# ── POST /upload/complaint-media ──────────────────────────────────────────────

@router.post("/complaint-media")
async def upload_complaint_media_endpoint(
    file: UploadFile = File(...),
    complaint_id: str = Form(...),
    media_type: str = Form(...),   # "photo" or "video"
    current_user=Depends(get_current_student),
):
    """
    Upload complaint evidence (photo or video) → Cloudinary.
    Appends the returned URL + metadata to the complaint record.
    """
    content_type = (file.content_type or "").lower()
    is_video = media_type.lower() == "video"

    if is_video:
        if content_type not in ALLOWED_VIDEO_TYPES:
            raise HTTPException(status_code=400, detail=f"Invalid video type '{content_type}'.")
        max_bytes = MAX_VIDEO_BYTES
    else:
        if content_type not in ALLOWED_IMAGE_TYPES:
            raise HTTPException(status_code=400, detail=f"Invalid image type '{content_type}'.")
        max_bytes = MAX_IMAGE_BYTES

    file_bytes = await file.read()
    if len(file_bytes) > max_bytes:
        label = "Video" if is_video else "Image"
        limit = MAX_VIDEO_MB if is_video else MAX_IMAGE_MB
        raise HTTPException(status_code=413, detail=f"{label} too large. Max {limit} MB.")
    if len(file_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty file.")

    # Upload to Cloudinary
    try:
        if is_video:
            result = await upload_complaint_video(file_bytes, file.filename or "complaint_video.mp4")
        else:
            result = await upload_complaint_image(file_bytes, file.filename or "complaint_photo.jpg")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Cloudinary upload failed: {str(e)}")

    # Validate complaint ID
    try:
        oid = ObjectId(complaint_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid complaint ID format.")

    # Build MediaItem document to push into MongoDB
    media_doc = {
        "url": result["url"],
        "thumbnail_url": result.get("thumbnail_url", result["url"]),
        "public_id": result.get("public_id", ""),
        "resource_type": result["resource_type"],
        "duration": result.get("duration"),
        "file_size": result.get("bytes"),
        "original_filename": file.filename or "",
        "uploaded_at": datetime.utcnow(),
    }

    db = get_db()
    await db.complaints.update_one(
        {"_id": oid, "student_id": current_user["_id"]},
        {
            "$push": {
                "media_items": media_doc,
                "media_urls": result["url"],          # keep backward-compat field
                "media_types": media_type.lower(),    # "photo" or "video"
            },
            "$inc": {"media_count": 1},
            "$set": {"updated_at": datetime.utcnow()},
        },
    )

    return {
        "success": True,
        "url": result["url"],
        "thumbnail_url": result.get("thumbnail_url", result["url"]),
        "public_id": result.get("public_id", ""),
        "resource_type": result["resource_type"],
        "duration": result.get("duration"),
        "complaint_id": complaint_id,
        "media_type": media_type,
        "message": "File uploaded to Cloudinary successfully.",
    }
