from fastapi import APIRouter, Depends
from database import get_db
from models import AdminDashboardStats, StudentDashboardStats, SOSResponse, ComplaintResponse, CCTVAlertResponse
from auth import get_current_admin, get_current_student
from routes.sos_routes import serialize_sos
from routes.complaint_routes import serialize_complaint
from routes.cctv_routes import serialize_cctv_alert
from datetime import datetime, date

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


# ── Admin Dashboard ───────────────────────────────────────────────────────────

@router.get("/admin", response_model=AdminDashboardStats)
async def admin_dashboard(current_user=Depends(get_current_admin)):
    db = get_db()

    total_students = await db.users.count_documents({"role": "student"})
    total_sos = await db.sos_requests.count_documents({})
    total_complaints = await db.complaints.count_documents({})
    total_cctv_alerts = await db.cctv_alerts.count_documents({})

    pending_sos = await db.sos_requests.count_documents({
        "status": {"$in": ["submitted", "under_review", "in_progress"]}
    })
    pending_complaints = await db.complaints.count_documents({
        "status": {"$in": ["submitted", "under_review", "in_progress"]}
    })
    pending_cctv_alerts = await db.cctv_alerts.count_documents({
        "status": {"$in": ["submitted", "under_review", "in_progress"]}
    })

    # Resolved today
    today_start = datetime.combine(date.today(), datetime.min.time())
    resolved_today = await db.sos_requests.count_documents({
        "status": "resolved", "updated_at": {"$gte": today_start}
    }) + await db.complaints.count_documents({
        "status": "resolved", "updated_at": {"$gte": today_start}
    }) + await db.cctv_alerts.count_documents({
        "status": "resolved", "updated_at": {"$gte": today_start}
    })

    # SOS by category
    sos_pipeline = [{"$group": {"_id": "$category", "count": {"$sum": 1}}}]
    sos_by_cat = {}
    async for doc in db.sos_requests.aggregate(sos_pipeline):
        sos_by_cat[doc["_id"]] = doc["count"]

    # Complaints by category
    comp_pipeline = [{"$group": {"_id": "$category", "count": {"$sum": 1}}}]
    comp_by_cat = {}
    async for doc in db.complaints.aggregate(comp_pipeline):
        comp_by_cat[doc["_id"]] = doc["count"]

    # CCTV alerts by incident type
    cctv_pipeline = [{"$group": {"_id": "$incident_type", "count": {"$sum": 1}}}]
    cctv_by_type = {}
    async for doc in db.cctv_alerts.aggregate(cctv_pipeline):
        cctv_by_type[doc["_id"]] = doc["count"]

    # Recent 5 of each
    recent_sos_cursor = db.sos_requests.find({}).sort("created_at", -1).limit(5)
    recent_sos = [serialize_sos(doc) async for doc in recent_sos_cursor]

    recent_comp_cursor = db.complaints.find({}).sort("created_at", -1).limit(5)
    recent_complaints = [serialize_complaint(doc) async for doc in recent_comp_cursor]

    recent_cctv_cursor = db.cctv_alerts.find({}).sort("detected_at", -1).limit(5)
    recent_cctv_alerts = [serialize_cctv_alert(doc) async for doc in recent_cctv_cursor]

    return AdminDashboardStats(
        total_students=total_students,
        total_sos=total_sos,
        total_complaints=total_complaints,
        total_cctv_alerts=total_cctv_alerts,
        pending_sos=pending_sos,
        pending_complaints=pending_complaints,
        pending_cctv_alerts=pending_cctv_alerts,
        resolved_today=resolved_today,
        sos_by_category=sos_by_cat,
        complaints_by_category=comp_by_cat,
        cctv_alerts_by_type=cctv_by_type,
        recent_sos=recent_sos,
        recent_complaints=recent_complaints,
        recent_cctv_alerts=recent_cctv_alerts,
    )


# ── Student Dashboard ─────────────────────────────────────────────────────────

@router.get("/student", response_model=StudentDashboardStats)
async def student_dashboard(current_user=Depends(get_current_student)):
    db = get_db()
    student_id = current_user["_id"]

    total_sos = await db.sos_requests.count_documents({"student_id": student_id})
    total_complaints = await db.complaints.count_documents({"student_id": student_id})

    pending_count = await db.sos_requests.count_documents({
        "student_id": student_id,
        "status": {"$in": ["submitted", "under_review", "in_progress"]}
    }) + await db.complaints.count_documents({
        "student_id": student_id,
        "status": {"$in": ["submitted", "under_review", "in_progress"]}
    })

    resolved_count = await db.sos_requests.count_documents({
        "student_id": student_id, "status": "resolved"
    }) + await db.complaints.count_documents({
        "student_id": student_id, "status": "resolved"
    })

    recent_sos_cursor = db.sos_requests.find({"student_id": student_id}).sort("created_at", -1).limit(3)
    recent_sos = [serialize_sos(doc) async for doc in recent_sos_cursor]

    recent_comp_cursor = db.complaints.find({"student_id": student_id}).sort("created_at", -1).limit(3)
    recent_complaints = [serialize_complaint(doc) async for doc in recent_comp_cursor]

    return StudentDashboardStats(
        total_sos=total_sos,
        total_complaints=total_complaints,
        pending_count=pending_count,
        resolved_count=resolved_count,
        recent_sos=recent_sos,
        recent_complaints=recent_complaints,
    )
