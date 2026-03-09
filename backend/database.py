from motor.motor_asyncio import AsyncIOMotorClient
from config import settings

client: AsyncIOMotorClient = None
db = None

async def connect_db():
    global client, db
    client = AsyncIOMotorClient(settings.MONGO_URI)
    db = client[settings.DB_NAME]
    # Create indexes
    await db.users.create_index("roll_number", unique=True)
    await db.users.create_index("email", unique=True)
    await db.sos_requests.create_index("student_id")
    await db.sos_requests.create_index("status")
    await db.sos_requests.create_index("created_at")
    await db.complaints.create_index("student_id")
    await db.complaints.create_index("status")
    await db.complaints.create_index("created_at")
    await db.cctv_alerts.create_index("camera_id")
    await db.cctv_alerts.create_index("status")
    await db.cctv_alerts.create_index("detected_at")
    await db.cctv_alerts.create_index("incident_type")
    print("✅ Connected to MongoDB")

async def close_db():
    global client
    if client:
        client.close()
        print("❌ MongoDB connection closed")

def get_db():
    return db
