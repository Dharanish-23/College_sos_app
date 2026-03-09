from fastapi import APIRouter, HTTPException, status, Depends
from database import get_db
from models import UserCreate, UserLogin, TokenResponse, UserResponse, UserRole
from auth import hash_password, verify_password, create_access_token, get_current_user
from bson import ObjectId

router = APIRouter(prefix="/auth", tags=["Auth"])


def serialize_user(user: dict) -> UserResponse:
    return UserResponse(
        id=str(user["_id"]),
        name=user["name"],
        roll_number=user["roll_number"],
        email=user["email"],
        role=user["role"],
        department=user.get("department"),
        year=user.get("year"),
        hostel_block=user.get("hostel_block"),
        phone=user.get("phone"),
        blood_group=user.get("blood_group"),
    )


@router.post("/register", response_model=UserResponse, status_code=201)
async def register(data: UserCreate):
    db = get_db()
    existing = await db.users.find_one({"roll_number": data.roll_number.upper()})
    if existing:
        raise HTTPException(status_code=400, detail="Roll number already registered")
    user_doc = {
        "name": data.name,
        "roll_number": data.roll_number.upper(),
        "email": data.email.lower(),
        "password": hash_password(data.password),
        "role": data.role.value,
        "department": data.department,
        "year": data.year,
        "hostel_block": data.hostel_block,
        "phone": data.phone,
        "blood_group": data.blood_group,
    }
    result = await db.users.insert_one(user_doc)
    user_doc["_id"] = result.inserted_id
    return serialize_user(user_doc)


@router.post("/login", response_model=TokenResponse)
async def login(data: UserLogin):
    db = get_db()
    user = await db.users.find_one({
        "roll_number": data.roll_number.upper(),
        "role": data.role.value
    })
    if not user or not verify_password(data.password, user["password"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    token = create_access_token({"sub": str(user["_id"]), "role": user["role"]})
    return TokenResponse(access_token=token, user=serialize_user(user))


@router.get("/me", response_model=UserResponse)
async def get_me(current_user=Depends(get_current_user)):
    return serialize_user(current_user)
