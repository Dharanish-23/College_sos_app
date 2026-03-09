from fastapi import APIRouter, HTTPException, Depends, Query
from database import get_db
from models import (
    ComplaintCreate, ComplaintResponse, ComplaintStatusUpdate,
    StatusUpdate, RequestStatus, MediaItem,
)
from auth import get_current_student, get_current_admin
from bson import ObjectId
from datetime import datetime
from typing import List, Optional

router = APIRouter(prefix="/complaints", tags=["Complaints"])


def serialize_complaint(doc: dict) -> ComplaintResponse:
    timeline = [
        StatusUpdate(
            message=t["message"],
            status=t["status"],
            updated_at=t["updated_at"],
            updated_by=t.get("updated_by"),
        )
        for t in doc.get("timeline", [])
    ]

    # Build rich MediaItem list from DB
    media_items = []
    for m in doc.get("media_items", []):
        try:
            url = m.get("url", "")
            # Determine resource type — check stored field first, then infer from URL
            resource_type = m.get("resource_type", "")
            if not resource_type:
                resource_type = "video" if any(ext in url.lower() for ext in [".mp4", ".mov", ".avi", ".webm", "/video/"]) else "image"
            thumbnail_url = m.get("thumbnail_url") or url
            media_items.append(MediaItem(
                url=url,
                thumbnail_url=thumbnail_url,
                public_id=m.get("public_id"),
                resource_type=resource_type,
                duration=m.get("duration"),
                file_size=m.get("file_size"),
                original_filename=m.get("original_filename"),
                uploaded_at=m.get("uploaded_at", datetime.utcnow()),
            ))
        except Exception:
            pass

    return ComplaintResponse(
        id=str(doc["_id"]),
        student_id=str(doc["student_id"]),
        student_name=doc["student_name"],
        roll_number=doc["roll_number"],
        department=doc.get("department"),
        category=doc["category"],
        subject=doc["subject"],
        description=doc["description"],
        location=doc["location"],
        is_anonymous=doc.get("is_anonymous", False),
        against_person=doc.get("against_person"),
        media_count=doc.get("media_count", 0),
        media_types=doc.get("media_types", []),
        media_urls=doc.get("media_urls", []),
        media_items=media_items,
        status=doc["status"],
        timeline=timeline,
        created_at=doc["created_at"],
        updated_at=doc["updated_at"],
    )


# ── Student: Submit complaint ─────────────────────────────────────────────────

@router.post("/", response_model=ComplaintResponse, status_code=201)
async def submit_complaint(data: ComplaintCreate, current_user=Depends(get_current_student)):
    db = get_db()
    now = datetime.utcnow()
    doc = {
        "student_id": current_user["_id"],
        "student_name": "Anonymous" if data.is_anonymous else current_user["name"],
        "roll_number": "****" if data.is_anonymous else current_user["roll_number"],
        "department": current_user.get("department"),
        "category": data.category.value,
        "subject": data.subject,
        "description": data.description,
        "location": data.location,
        "is_anonymous": data.is_anonymous,
        "against_person": data.against_person,
        "media_count": 0,           # incremented on each upload
        "media_types": [],
        "media_urls": [],
        "media_items": [],
        "status": RequestStatus.submitted.value,
        "timeline": [{
            "message": "Complaint filed successfully. Assigned to grievance committee.",
            "status": RequestStatus.submitted.value,
            "updated_at": now,
            "updated_by": None,
        }],
        "created_at": now,
        "updated_at": now,
    }
    result = await db.complaints.insert_one(doc)
    doc["_id"] = result.inserted_id
    return serialize_complaint(doc)


# ── Student: Get own complaints ───────────────────────────────────────────────

@router.get("/my", response_model=List[ComplaintResponse])
async def my_complaints(current_user=Depends(get_current_student)):
    db = get_db()
    cursor = db.complaints.find({"student_id": current_user["_id"]}).sort("created_at", -1)
    return [serialize_complaint(doc) async for doc in cursor]


# ── Student: Single complaint ─────────────────────────────────────────────────

@router.get("/my/{complaint_id}", response_model=ComplaintResponse)
async def get_my_complaint(complaint_id: str, current_user=Depends(get_current_student)):
    db = get_db()
    doc = await db.complaints.find_one(
        {"_id": ObjectId(complaint_id), "student_id": current_user["_id"]}
    )
    if not doc:
        raise HTTPException(status_code=404, detail="Complaint not found")
    return serialize_complaint(doc)


# ── Admin: Get all complaints ─────────────────────────────────────────────────

@router.get("/admin/all", response_model=List[ComplaintResponse])
async def admin_get_all_complaints(
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
    cursor = db.complaints.find(query).sort("created_at", -1)
    return [serialize_complaint(doc) async for doc in cursor]


# ── Admin: Update complaint status ────────────────────────────────────────────

@router.patch("/admin/{complaint_id}/status", response_model=ComplaintResponse)
async def update_complaint_status(
    complaint_id: str,
    data: ComplaintStatusUpdate,
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
    result = await db.complaints.update_one(
        {"_id": ObjectId(complaint_id)},
        {
            "$set": {"status": data.status.value, "updated_at": now},
            "$push": {"timeline": timeline_entry},
        },
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Complaint not found")
    doc = await db.complaints.find_one({"_id": ObjectId(complaint_id)})
    return serialize_complaint(doc)
