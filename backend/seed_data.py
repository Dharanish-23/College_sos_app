"""
Enhanced seed script with sample SOS and complaints data.
Run once to populate the MongoDB database with demo data.
Usage:  cd backend && python seed_data.py
"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext
from datetime import datetime, timedelta
from config import settings
from bson import ObjectId

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

STUDENTS = [
    {"name": "Arjun Kumar",   "roll_number": "2023CS001", "email": "2023cs001@college.edu", "password": "pass123", "department": "Computer Science", "year": "3rd Year", "hostel_block": "Block C, Room 204", "phone": "+91-98765-43210", "blood_group": "B+"},
    {"name": "Priya Sharma",  "roll_number": "2023CS002", "email": "2023cs002@college.edu", "password": "pass456", "department": "Computer Science", "year": "3rd Year", "hostel_block": "Block A, Room 102", "phone": "+91-98765-11111", "blood_group": "O+"},
    {"name": "Ravi Patel",    "roll_number": "2022EC010", "email": "2022ec010@college.edu", "password": "pass789", "department": "Electronics",      "year": "4th Year", "hostel_block": "Block B, Room 310", "phone": "+91-98765-22222", "blood_group": "A+"},
    {"name": "Sneha Reddy",   "roll_number": "2023ME005", "email": "2023me005@college.edu", "password": "pass321", "department": "Mechanical",       "year": "3rd Year", "hostel_block": "Block D, Room 112", "phone": "+91-98765-33333", "blood_group": "AB+"},
    {"name": "Vikram Singh",  "roll_number": "2024CS012", "email": "2024cs012@college.edu", "password": "pass654", "department": "Computer Science", "year": "2nd Year", "hostel_block": "Block C, Room 108", "phone": "+91-98765-44444", "blood_group": "O-"},
    {"name": "Ananya Iyer",   "roll_number": "2023CE008", "email": "2023ce008@college.edu", "password": "pass987", "department": "Civil Engineering","year": "3rd Year", "hostel_block": "Block A, Room 205", "phone": "+91-98765-55555", "blood_group": "A-"},
    {"name": "Karan Mehta",   "roll_number": "2022ME015", "email": "2022me015@college.edu", "password": "pass111", "department": "Mechanical",       "year": "4th Year", "hostel_block": "Block B, Room 420", "phone": "+91-98765-66666", "blood_group": "B-"},
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

    # ── Create indexes ─────────────────────────────────────────────────────
    await db.users.create_index("roll_number", unique=True)
    await db.users.create_index("email", unique=True)
    await db.sos_requests.create_index("student_id")
    await db.sos_requests.create_index("status")
    await db.complaints.create_index("student_id")
    await db.complaints.create_index("status")

    # ── Seed users ─────────────────────────────────────────────────────────
    print("\n📦 Seeding users...")
    student_ids = {}
    for s in STUDENTS:
        existing = await db.users.find_one({"roll_number": s["roll_number"]})
        if existing:
            print(f"  ⏭  {s['roll_number']} already exists")
            student_ids[s["roll_number"]] = existing["_id"]
            continue
        doc = {**s, "password": pwd_context.hash(s["password"]), "role": "student"}
        result = await db.users.insert_one(doc)
        student_ids[s["roll_number"]] = result.inserted_id
        print(f"  ✅ {s['roll_number']} / {s['name']}")

    admin_existing = await db.users.find_one({"roll_number": ADMIN["roll_number"]})
    if not admin_existing:
        doc = {**ADMIN, "password": pwd_context.hash(ADMIN["password"])}
        await db.users.insert_one(doc)
        print(f"  ✅ Admin {ADMIN['roll_number']}")
    else:
        print(f"  ⏭  Admin already exists")

    # ── Seed SOS requests ──────────────────────────────────────────────────
    print("\n🆘 Seeding SOS requests...")
    sos_count = await db.sos_requests.count_documents({})
    if sos_count > 0:
        print(f"  ⏭  {sos_count} SOS records already exist, skipping")
    else:
        now = datetime.utcnow()
        arjun_id = student_ids.get("2023CS001")
        priya_id = student_ids.get("2023CS002")
        ravi_id  = student_ids.get("2022EC010")
        sneha_id = student_ids.get("2023ME005")

        sos_samples = [
            {
                "student_id": arjun_id,
                "student_name": "Arjun Kumar",
                "roll_number": "2023CS001",
                "department": "Computer Science",
                "category": "medical",
                "description": "Severe headache and dizziness in lab. Unable to stand.",
                "location": "CS Lab 3, Block D",
                "is_anonymous": False,
                "has_video": False,
                "status": "resolved",
                "timeline": [
                    {"message": "SOS alert submitted. Campus security notified immediately.", "status": "submitted", "updated_at": now - timedelta(days=5, hours=3), "updated_by": None},
                    {"message": "Security team dispatched to CS Lab 3.", "status": "in_progress", "updated_at": now - timedelta(days=5, hours=2, minutes=50), "updated_by": "Dr. Rajesh Nair"},
                    {"message": "Student escorted to health center. Stable condition confirmed.", "status": "resolved", "updated_at": now - timedelta(days=5, hours=2), "updated_by": "Dr. Rajesh Nair"},
                ],
                "created_at": now - timedelta(days=5, hours=3),
                "updated_at": now - timedelta(days=5, hours=2),
            },
            {
                "student_id": priya_id,
                "student_name": "Anonymous",
                "roll_number": "****",
                "department": "Computer Science",
                "category": "harassment",
                "description": "Being verbally harassed by senior students near the library.",
                "location": "Library entrance, Block A",
                "is_anonymous": True,
                "has_video": True,
                "status": "in_progress",
                "timeline": [
                    {"message": "SOS alert submitted. Campus security notified immediately.", "status": "submitted", "updated_at": now - timedelta(days=2), "updated_by": None},
                    {"message": "Case registered. Anti-ragging committee has been informed.", "status": "under_review", "updated_at": now - timedelta(days=1, hours=20), "updated_by": "Dr. Rajesh Nair"},
                    {"message": "Investigation in progress. Witnesses being questioned.", "status": "in_progress", "updated_at": now - timedelta(days=1), "updated_by": "Dr. Rajesh Nair"},
                ],
                "created_at": now - timedelta(days=2),
                "updated_at": now - timedelta(days=1),
            },
            {
                "student_id": ravi_id,
                "student_name": "Ravi Patel",
                "roll_number": "2022EC010",
                "department": "Electronics",
                "category": "accident",
                "description": "Minor electrical shock in ECE lab. Hand feels numb.",
                "location": "ECE Lab 2, Block B",
                "is_anonymous": False,
                "has_video": False,
                "status": "submitted",
                "timeline": [
                    {"message": "SOS alert submitted. Campus security notified immediately.", "status": "submitted", "updated_at": now - timedelta(hours=3), "updated_by": None},
                ],
                "created_at": now - timedelta(hours=3),
                "updated_at": now - timedelta(hours=3),
            },
            {
                "student_id": sneha_id,
                "student_name": "Sneha Reddy",
                "roll_number": "2023ME005",
                "department": "Mechanical",
                "category": "mental_health",
                "description": "Feeling extremely stressed and having panic attacks. Need counseling urgently.",
                "location": "Hostel Block D, Room 112",
                "is_anonymous": False,
                "has_video": False,
                "status": "under_review",
                "timeline": [
                    {"message": "SOS alert submitted. Campus security notified immediately.", "status": "submitted", "updated_at": now - timedelta(days=1, hours=5), "updated_by": None},
                    {"message": "Counseling session scheduled for tomorrow at 10 AM.", "status": "under_review", "updated_at": now - timedelta(days=1, hours=2), "updated_by": "Dr. Rajesh Nair"},
                ],
                "created_at": now - timedelta(days=1, hours=5),
                "updated_at": now - timedelta(days=1, hours=2),
            },
        ]
        for sos in sos_samples:
            await db.sos_requests.insert_one(sos)
        print(f"  ✅ Inserted {len(sos_samples)} SOS records")

    # ── Seed Complaints ────────────────────────────────────────────────────
    print("\n📋 Seeding complaints...")
    comp_count = await db.complaints.count_documents({})
    if comp_count > 0:
        print(f"  ⏭  {comp_count} complaint records already exist, skipping")
    else:
        now = datetime.utcnow()
        arjun_id = student_ids.get("2023CS001")
        priya_id = student_ids.get("2023CS002")
        ravi_id  = student_ids.get("2022EC010")
        vikram_id = student_ids.get("2024CS012")

        complaint_samples = [
            {
                "student_id": arjun_id,
                "student_name": "Arjun Kumar",
                "roll_number": "2023CS001",
                "department": "Computer Science",
                "category": "facility_issue",
                "subject": "Broken AC in Hostel Room",
                "description": "The AC in Block C Room 204 has not been working for over 2 weeks. Room temperature is unbearable especially during afternoon. Multiple requests to hostel office have been ignored.",
                "location": "Block C, Room 204",
                "is_anonymous": False,
                "against_person": None,
                "media_count": 2,
                "media_types": ["photo", "photo"],
                "status": "resolved",
                "timeline": [
                    {"message": "Complaint filed successfully. Assigned to grievance committee.", "status": "submitted", "updated_at": now - timedelta(days=10), "updated_by": None},
                    {"message": "Maintenance team inspection scheduled.", "status": "under_review", "updated_at": now - timedelta(days=8), "updated_by": "Dr. Rajesh Nair"},
                    {"message": "AC unit replaced. Please confirm if the issue is resolved.", "status": "in_progress", "updated_at": now - timedelta(days=6), "updated_by": "Dr. Rajesh Nair"},
                    {"message": "Issue resolved. New AC installed and functioning properly.", "status": "resolved", "updated_at": now - timedelta(days=5), "updated_by": "Dr. Rajesh Nair"},
                ],
                "created_at": now - timedelta(days=10),
                "updated_at": now - timedelta(days=5),
            },
            {
                "student_id": priya_id,
                "student_name": "Anonymous",
                "roll_number": "****",
                "department": "Computer Science",
                "category": "ragging",
                "subject": "Ragging by Senior Students",
                "description": "Senior students from 4th year have been ragging first year students in the hostel corridor at night. This has been happening for the past week. They demand money and force them to do embarrassing acts.",
                "location": "Hostel Block A, Ground Floor",
                "is_anonymous": True,
                "against_person": "Unknown 4th year students",
                "media_count": 0,
                "media_types": [],
                "status": "in_progress",
                "timeline": [
                    {"message": "Complaint filed successfully. Assigned to grievance committee.", "status": "submitted", "updated_at": now - timedelta(days=3), "updated_by": None},
                    {"message": "Anti-ragging committee notified. CCTV footage being reviewed.", "status": "under_review", "updated_at": now - timedelta(days=2), "updated_by": "Dr. Rajesh Nair"},
                    {"message": "Suspects identified. Disciplinary hearing scheduled.", "status": "in_progress", "updated_at": now - timedelta(days=1), "updated_by": "Dr. Rajesh Nair"},
                ],
                "created_at": now - timedelta(days=3),
                "updated_at": now - timedelta(days=1),
            },
            {
                "student_id": ravi_id,
                "student_name": "Ravi Patel",
                "roll_number": "2022EC010",
                "department": "Electronics",
                "category": "academic_misconduct",
                "subject": "Unfair Grading in Internal Assessment",
                "description": "My internal assessment marks were drastically reduced without explanation after I raised concerns about lab equipment in class. This seems like a retaliatory action by Prof. XYZ. Other students who got similar answers received much higher marks.",
                "location": "Department of Electronics",
                "is_anonymous": False,
                "against_person": "Prof. XYZ (ECE Dept)",
                "media_count": 1,
                "media_types": ["photo"],
                "status": "under_review",
                "timeline": [
                    {"message": "Complaint filed successfully. Assigned to grievance committee.", "status": "submitted", "updated_at": now - timedelta(days=4), "updated_by": None},
                    {"message": "Academic committee reviewing the assessment records.", "status": "under_review", "updated_at": now - timedelta(days=2), "updated_by": "Dr. Rajesh Nair"},
                ],
                "created_at": now - timedelta(days=4),
                "updated_at": now - timedelta(days=2),
            },
            {
                "student_id": vikram_id,
                "student_name": "Vikram Singh",
                "roll_number": "2024CS012",
                "department": "Computer Science",
                "category": "facility_issue",
                "subject": "Wi-Fi Not Working in Hostel for 5 Days",
                "description": "The Wi-Fi in Block C has been completely non-functional for the past 5 days. Students are unable to attend online classes and submit assignments. This is severely affecting academic performance.",
                "location": "Block C Hostel",
                "is_anonymous": False,
                "against_person": None,
                "media_count": 0,
                "media_types": [],
                "status": "submitted",
                "timeline": [
                    {"message": "Complaint filed successfully. Assigned to grievance committee.", "status": "submitted", "updated_at": now - timedelta(hours=6), "updated_by": None},
                ],
                "created_at": now - timedelta(hours=6),
                "updated_at": now - timedelta(hours=6),
            },
        ]
        for comp in complaint_samples:
            await db.complaints.insert_one(comp)
        print(f"  ✅ Inserted {len(complaint_samples)} complaint records")

    client.close()
    print("\n" + "="*50)
    print("🎉 Seeding complete!")
    print("="*50)
    print("\n── LOGIN CREDENTIALS ──────────────────────────────")
    print("STUDENTS (use 'student' role):")
    for s in STUDENTS:
        print(f"  Roll: {s['roll_number']:<15}  Pass: {s['password']}")
    print("\nADMIN (use 'admin' role):")
    print(f"  Roll: {ADMIN['roll_number']:<15}  Pass: {ADMIN['password']}")
    print("\n── API DOCS ────────────────────────────────────────")
    print("  http://localhost:8000/docs")
    print("="*50)

if __name__ == "__main__":
    asyncio.run(seed())
