from fastapi import APIRouter, Depends
from database import get_db
from models import UserResponse
from auth import get_current_admin
from bson import ObjectId
from typing import List

router = APIRouter(prefix="/admin", tags=["Admin"])


def serialize_user(u):
    return UserResponse(
        id=str(u["_id"]),
        name=u["name"],
        roll_number=u["roll_number"],
        email=u["email"],
        role=u["role"],
        department=u.get("department"),
        year=u.get("year"),
        hostel_block=u.get("hostel_block"),
        phone=u.get("phone"),
        blood_group=u.get("blood_group"),
    )


@router.get("/students", response_model=List[UserResponse])
async def get_all_students(current_user=Depends(get_current_admin)):
    db = get_db()
    cursor = db.users.find({"role": "student"}).sort("name", 1)
    return [serialize_user(u) async for u in cursor]
