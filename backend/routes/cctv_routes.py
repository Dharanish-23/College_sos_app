from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from typing import List, Optional
from datetime import datetime
from bson import ObjectId
from database import get_db
from auth import get_current_admin
from models import (
    CCTVAlertCreate,
    CCTVAlertResponse,
    CCTVAlertStatusUpdate,
    StatusUpdate,
    RequestStatus,
)
from cloudinary_service import upload_video_to_cloudinary
from yolo_analyzer import analyze_video_for_persons

router = APIRouter(prefix="/cctv", tags=["CCTV Monitoring"])


def serialize_cctv_alert(doc: dict) -> dict:
    """Convert MongoDB document to CCTVAlertResponse format"""
    return {
        "id": str(doc["_id"]),
        "camera_id": doc["camera_id"],
        "camera_location": doc["camera_location"],
        "incident_type": doc["incident_type"],
        "description": doc["description"],
        "confidence_score": doc.get("confidence_score", 0.0),
        "video_url": doc.get("video_url"),
        "video_thumbnail_url": doc.get("video_thumbnail_url"),
        "video_duration": doc.get("video_duration"),
        "status": doc["status"],
        "timeline": doc.get("timeline", []),
        "detected_at": doc["detected_at"],
        "created_at": doc["created_at"],
        "updated_at": doc["updated_at"],
        "acknowledged_by": doc.get("acknowledged_by"),
        "acknowledged_at": doc.get("acknowledged_at"),
    }


@router.post("/simulate-alert", response_model=CCTVAlertResponse)
async def simulate_cctv_alert(
    alert: CCTVAlertCreate,
    current_user=Depends(get_current_admin),
):
    """
    Simulate a CCTV alert detection (for prototype/demo purposes)
    In production, this would be triggered by AI detection system
    """
    db = get_db()
    
    now = datetime.utcnow()
    alert_doc = {
        "camera_id": alert.camera_id,
        "camera_location": alert.camera_location,
        "incident_type": alert.incident_type,
        "description": alert.description,
        "confidence_score": alert.confidence_score,
        "status": RequestStatus.submitted,
        "timeline": [
            {
                "message": f"Incident detected by Camera {alert.camera_id}",
                "status": RequestStatus.submitted,
                "updated_at": now,
                "updated_by": "CCTV_SYSTEM",
            }
        ],
        "detected_at": alert.detected_at,
        "created_at": now,
        "updated_at": now,
    }
    
    result = await db.cctv_alerts.insert_one(alert_doc)
    alert_doc["_id"] = result.inserted_id
    
    return serialize_cctv_alert(alert_doc)


@router.post("/upload-alert-video/{alert_id}")
async def upload_cctv_video(
    alert_id: str,
    video: UploadFile = File(...),
    current_user=Depends(get_current_admin),
):
    """Upload CCTV footage for an alert"""
    db = get_db()
    
    # Verify alert exists
    alert = await db.cctv_alerts.find_one({"_id": ObjectId(alert_id)})
    if not alert:
        raise HTTPException(status_code=404, detail="CCTV alert not found")
    
    # Upload to Cloudinary
    video_bytes = await video.read()
    upload_result = await upload_video_to_cloudinary(
        video_bytes,
        folder="college_sos/cctv",
        public_id=f"cctv_{alert_id}",
    )
    
    # Update alert with video URL
    await db.cctv_alerts.update_one(
        {"_id": ObjectId(alert_id)},
        {
            "$set": {
                "video_url": upload_result["secure_url"],
                "video_thumbnail_url": upload_result.get("thumbnail_url"),
                "video_duration": upload_result.get("duration"),
                "updated_at": datetime.utcnow(),
            }
        },
    )
    
    return {
        "message": "CCTV video uploaded successfully",
        "video_url": upload_result["secure_url"],
        "thumbnail_url": upload_result.get("thumbnail_url"),
    }


@router.get("/alerts", response_model=List[CCTVAlertResponse])
async def get_all_cctv_alerts(
    status: Optional[str] = None,
    incident_type: Optional[str] = None,
    limit: int = 50,
    current_user=Depends(get_current_admin),
):
    """Get all CCTV alerts (admin only)"""
    db = get_db()
    
    query = {}
    if status:
        query["status"] = status
    if incident_type:
        query["incident_type"] = incident_type
    
    cursor = db.cctv_alerts.find(query).sort("detected_at", -1).limit(limit)
    alerts = await cursor.to_list(length=limit)
    
    return [serialize_cctv_alert(alert) for alert in alerts]


@router.get("/alerts/pending", response_model=List[CCTVAlertResponse])
async def get_pending_cctv_alerts(
    current_user=Depends(get_current_admin),
):
    """Get all pending CCTV alerts requiring attention"""
    db = get_db()
    
    cursor = db.cctv_alerts.find(
        {"status": {"$in": ["submitted", "under_review"]}}
    ).sort("detected_at", -1)
    
    alerts = await cursor.to_list(length=100)
    return [serialize_cctv_alert(alert) for alert in alerts]


@router.get("/alerts/{alert_id}", response_model=CCTVAlertResponse)
async def get_cctv_alert_details(
    alert_id: str,
    current_user=Depends(get_current_admin),
):
    """Get specific CCTV alert details"""
    db = get_db()
    
    alert = await db.cctv_alerts.find_one({"_id": ObjectId(alert_id)})
    if not alert:
        raise HTTPException(status_code=404, detail="CCTV alert not found")
    
    return serialize_cctv_alert(alert)


@router.patch("/alerts/{alert_id}/acknowledge")
async def acknowledge_cctv_alert(
    alert_id: str,
    current_user=Depends(get_current_admin),
):
    """Acknowledge a CCTV alert (admin has seen it)"""
    db = get_db()
    
    alert = await db.cctv_alerts.find_one({"_id": ObjectId(alert_id)})
    if not alert:
        raise HTTPException(status_code=404, detail="CCTV alert not found")
    
    now = datetime.utcnow()
    admin_name = current_user.get("name", "Admin")
    
    await db.cctv_alerts.update_one(
        {"_id": ObjectId(alert_id)},
        {
            "$set": {
                "acknowledged_by": admin_name,
                "acknowledged_at": now,
                "status": RequestStatus.under_review,
                "updated_at": now,
            },
            "$push": {
                "timeline": {
                    "message": f"Alert acknowledged by {admin_name}",
                    "status": RequestStatus.under_review,
                    "updated_at": now,
                    "updated_by": admin_name,
                }
            },
        },
    )
    
    return {"message": "CCTV alert acknowledged successfully"}


@router.patch("/alerts/{alert_id}/status", response_model=CCTVAlertResponse)
async def update_cctv_alert_status(
    alert_id: str,
    update: CCTVAlertStatusUpdate,
    current_user=Depends(get_current_admin),
):
    """Update CCTV alert status with admin response"""
    db = get_db()
    
    alert = await db.cctv_alerts.find_one({"_id": ObjectId(alert_id)})
    if not alert:
        raise HTTPException(status_code=404, detail="CCTV alert not found")
    
    now = datetime.utcnow()
    admin_name = current_user.get("name", "Admin")
    
    timeline_entry = {
        "message": update.message,
        "status": update.status,
        "updated_at": now,
        "updated_by": admin_name,
    }
    
    await db.cctv_alerts.update_one(
        {"_id": ObjectId(alert_id)},
        {
            "$set": {
                "status": update.status,
                "updated_at": now,
            },
            "$push": {"timeline": timeline_entry},
        },
    )
    
    updated_alert = await db.cctv_alerts.find_one({"_id": ObjectId(alert_id)})
    return serialize_cctv_alert(updated_alert)


# ── POST /cctv/analyze-video ─────────────────────────────────────────────────

@router.post("/analyze-video")
async def analyze_cctv_video(
    video: UploadFile = File(...),
    current_user=Depends(get_current_admin),
):
    """
    Analyze uploaded video with YOLOv8 person detection.
    Returns: incident_detected, verdict, persons_detected, confidence, etc.
    """
    # Validate file type
    content_type = (video.content_type or "").lower()
    allowed_types = {"video/mp4", "video/quicktime", "video/x-msvideo", "video/webm", "video/3gpp", "video/mpeg"}
    if content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type '{content_type}'. Allowed: mp4, mov, avi, webm, 3gp."
        )

    video_bytes = await video.read()
    if len(video_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty video file.")
    if len(video_bytes) > 500 * 1024 * 1024:  # 500 MB hard limit
        raise HTTPException(status_code=413, detail="Video too large. Max 500 MB.")

    try:
        result = await analyze_video_for_persons(video_bytes)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Video analysis failed: {str(e)}")

    # If YOLO itself returned an error message, propagate it so the client
    # knows what went wrong (e.g. unsupported codec) rather than silently
    # returning false with no explanation.
    if result.get("error") and result["frames_analyzed"] == 0:
        raise HTTPException(
            status_code=422,
            detail=f"Video could not be analyzed: {result['error']}"
        )

    return {
        "success": True,
        "incident_detected": result["incident_detected"],   # True ONLY if person detected
        "verdict": result["verdict"],
        "persons_detected": result["persons_detected"],
        "person_frames": result["person_frames"],
        "frames_analyzed": result["frames_analyzed"],
        "confidence": result["confidence"],
        "duration_seconds": result.get("duration_seconds", 0),
        "severity": result.get("severity", "none"),
        "error": result.get("error"),
    }


@router.get("/cameras/list")
async def get_camera_list(current_user=Depends(get_current_admin)):
    """Get list of all CCTV cameras in the system"""
    # In a real system, this would come from a cameras database
    # For prototype, return static list
    cameras = [
        {"id": "CAM-001", "location": "Main Gate", "status": "active"},
        {"id": "CAM-002", "location": "Admin Block Entrance", "status": "active"},
        {"id": "CAM-003", "location": "Library Ground Floor", "status": "active"},
        {"id": "CAM-004", "location": "Cafeteria", "status": "active"},
        {"id": "CAM-005", "location": "Hostel Block A", "status": "active"},
        {"id": "CAM-006", "location": "Hostel Block B", "status": "active"},
        {"id": "CAM-007", "location": "Sports Complex", "status": "active"},
        {"id": "CAM-008", "location": "Parking Area", "status": "active"},
        {"id": "CAM-009", "location": "Academic Block 1", "status": "active"},
        {"id": "CAM-010", "location": "Academic Block 2", "status": "active"},
    ]
    return {"cameras": cameras, "total": len(cameras)}
