from fastapi import APIRouter, HTTPException, Depends, Query
from database import get_db
from models import SOSCreate, SOSResponse, SOSStatusUpdate, StatusUpdate, RequestStatus
from auth import get_current_student, get_current_admin
from bson import ObjectId
from datetime import datetime
from typing import List, Optional

router = APIRouter(prefix="/sos", tags=["SOS"])


def serialize_sos(doc: dict) -> SOSResponse:
    timeline = [
        StatusUpdate(
            message=t["message"],
            status=t["status"],
            updated_at=t["updated_at"],
            updated_by=t.get("updated_by"),
        )
        for t in doc.get("timeline", [])
    ]
    return SOSResponse(
        id=str(doc["_id"]),
        student_id=str(doc["student_id"]),
        student_name=doc["student_name"],
        roll_number=doc["roll_number"],
        department=doc.get("department"),
        category=doc["category"],
        description=doc["description"],
        location=doc["location"],
        is_anonymous=doc.get("is_anonymous", False),
        has_video=doc.get("has_video", False),
        video_url=doc.get("video_url"),
        video_thumbnail_url=doc.get("video_thumbnail_url"),
        video_duration=doc.get("video_duration"),
        status=doc["status"],
        timeline=timeline,
        created_at=doc["created_at"],
        updated_at=doc["updated_at"],
    )


# ── Student: Submit SOS ──────────────────────────────────────────────────────

@router.post("/", response_model=SOSResponse, status_code=201)
async def submit_sos(data: SOSCreate, current_user=Depends(get_current_student)):
    db = get_db()
    now = datetime.utcnow()
    doc = {
        "student_id": current_user["_id"],
        "student_name": "Anonymous" if data.is_anonymous else current_user["name"],
        "roll_number": "****" if data.is_anonymous else current_user["roll_number"],
        "department": current_user.get("department"),
        "category": data.category.value,
        "description": data.description,
        "location": data.location,
        "is_anonymous": data.is_anonymous,
        "has_video": data.has_video,
        "video_url": None,
        "video_thumbnail_url": None,
        "video_duration": None,
        "status": RequestStatus.submitted.value,
        "timeline": [{
            "message": "SOS alert submitted. Campus security notified immediately.",
            "status": RequestStatus.submitted.value,
            "updated_at": now,
            "updated_by": None,
        }],
        "created_at": now,
        "updated_at": now,
    }
    result = await db.sos_requests.insert_one(doc)
    doc["_id"] = result.inserted_id
    return serialize_sos(doc)


# ── Student: Get own SOS list ────────────────────────────────────────────────

@router.get("/my", response_model=List[SOSResponse])
async def my_sos(current_user=Depends(get_current_student)):
    db = get_db()
    cursor = db.sos_requests.find({"student_id": current_user["_id"]}).sort("created_at", -1)
    return [serialize_sos(doc) async for doc in cursor]


# ── Student: Get single SOS ──────────────────────────────────────────────────

@router.get("/my/{sos_id}", response_model=SOSResponse)
async def get_my_sos(sos_id: str, current_user=Depends(get_current_student)):
    db = get_db()
    doc = await db.sos_requests.find_one({"_id": ObjectId(sos_id), "student_id": current_user["_id"]})
    if not doc:
        raise HTTPException(status_code=404, detail="SOS not found")
    return serialize_sos(doc)


# ── Admin: Get all SOS ───────────────────────────────────────────────────────

@router.get("/admin/all", response_model=List[SOSResponse])
async def admin_get_all_sos(
    status: Optional[str] = Query(None),
    category: Optional[str] = Query(None),
    current_user=Depends(get_current_admin),
):
    db = get_db()
    query = {}
    if status:
        query["status"] = status
    if category:
        query["category"] = category
    cursor = db.sos_requests.find(query).sort("created_at", -1)
    return [serialize_sos(doc) async for doc in cursor]


# ── Admin: Update SOS status ─────────────────────────────────────────────────

@router.patch("/admin/{sos_id}/status", response_model=SOSResponse)
async def update_sos_status(
    sos_id: str,
    data: SOSStatusUpdate,
    current_user=Depends(get_current_admin),
):
    db = get_db()
    now = datetime.utcnow()
    timeline_entry = {
        "message": data.message,
        "status": data.status.value,
        "updated_at": now,
        "updated_by": current_user["name"],
    }
    result = await db.sos_requests.update_one(
        {"_id": ObjectId(sos_id)},
        {
            "$set": {"status": data.status.value, "updated_at": now},
            "$push": {"timeline": timeline_entry},
        },
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="SOS not found")
    doc = await db.sos_requests.find_one({"_id": ObjectId(sos_id)})
    return serialize_sos(doc)
