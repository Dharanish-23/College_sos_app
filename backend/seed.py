"""
Seed script — run once to insert sample students and an admin into MongoDB.
Usage:  python seed.py
"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext
from config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

STUDENTS = [
    {"name": "Arjun Kumar",   "roll_number": "2023CS001", "email": "2023cs001@college.edu", "password": "pass123", "department": "Computer Science", "year": "3rd Year", "hostel_block": "Block C, Room 204", "phone": "+91-98765-43210", "blood_group": "B+"},
    {"name": "Priya Sharma",  "roll_number": "2023CS002", "email": "2023cs002@college.edu", "password": "pass456", "department": "Computer Science", "year": "3rd Year", "hostel_block": "Block A, Room 102", "phone": "+91-98765-11111", "blood_group": "O+"},
    {"name": "Ravi Patel",    "roll_number": "2022EC010", "email": "2022ec010@college.edu", "password": "pass789", "department": "Electronics",      "year": "4th Year", "hostel_block": "Block B, Room 310", "phone": "+91-98765-22222", "blood_group": "A+"},
    {"name": "Sneha Reddy",   "roll_number": "2023ME005", "email": "2023me005@college.edu", "password": "pass321", "department": "Mechanical",       "year": "3rd Year", "hostel_block": "Block D, Room 112", "phone": "+91-98765-33333", "blood_group": "AB+"},
    {"name": "Vikram Singh",  "roll_number": "2024CS012", "email": "2024cs012@college.edu", "password": "pass654", "department": "Computer Science", "year": "2nd Year", "hostel_block": "Block C, Room 108", "phone": "+91-98765-44444", "blood_group": "O-"},
]

ADMIN = {
    "name": "Dr. Rajesh Nair",
    "roll_number": "ADMIN001",
    "email": "admin@college.edu",
    "password": "admin123",
    "role": "admin",
    "department": "Administration",
}

async def seed():
    client = AsyncIOMotorClient(settings.MONGO_URI)
    db = client[settings.DB_NAME]

    print("Seeding students...")
    for s in STUDENTS:
        existing = await db.users.find_one({"roll_number": s["roll_number"]})
        if existing:
            print(f"  ⏭  {s['roll_number']} already exists, skipping")
            continue
        doc = {**s, "password": pwd_context.hash(s["password"]), "role": "student"}
        await db.users.insert_one(doc)
        print(f"  ✅ Inserted student {s['roll_number']} / {s['name']}")

    print("Seeding admin...")
    existing_admin = await db.users.find_one({"roll_number": ADMIN["roll_number"]})
    if existing_admin:
        print("  ⏭  Admin already exists, skipping")
    else:
        doc = {**ADMIN, "password": pwd_context.hash(ADMIN["password"])}
        await db.users.insert_one(doc)
        print(f"  ✅ Inserted admin {ADMIN['roll_number']} / {ADMIN['name']}")

    client.close()
    print("\n🎉 Seeding complete!")
    print("\n── Login credentials ──────────────────────────")
    print("STUDENTS:")
    for s in STUDENTS:
        print(f"  Roll: {s['roll_number']}  Pass: {s['password']}")
    print("ADMIN:")
    print(f"  Roll: {ADMIN['roll_number']}  Pass: {ADMIN['password']}")

if __name__ == "__main__":
    asyncio.run(seed())
