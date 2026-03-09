"""
Seed script to add sample CCTV alerts to the database
Run this after starting the backend to populate demo CCTV data
"""
import asyncio
from datetime import datetime, timedelta
from motor.motor_asyncio import AsyncIOMotorClient
from config import settings

async def seed_cctv_alerts():
    client = AsyncIOMotorClient(settings.MONGO_URI)
    db = client[settings.DB_NAME]
    
    # Clear existing CCTV alerts
    await db.cctv_alerts.delete_many({})
    print("🗑️  Cleared existing CCTV alerts")
    
    now = datetime.utcnow()
    
    sample_alerts = [
        {
            "camera_id": "CAM-010",
            "camera_location": "Academic Block 2 - Corridor",
            "incident_type": "fighting",
            "description": "Physical altercation detected between 2-3 individuals",
            "confidence_score": 0.92,
            "status": "submitted",
            "timeline": [
                {
                    "message": "Incident detected by Camera CAM-010",
                    "status": "submitted",
                    "updated_at": now - timedelta(minutes=5),
                    "updated_by": "CCTV_SYSTEM",
                }
            ],
            "detected_at": now - timedelta(minutes=5),
            "created_at": now - timedelta(minutes=5),
            "updated_at": now - timedelta(minutes=5),
        },
        {
            "camera_id": "CAM-004",
            "camera_location": "Cafeteria - Main Hall",
            "incident_type": "large_crowd",
            "description": "Unusual crowd gathering detected (50+ people)",
            "confidence_score": 0.88,
            "status": "under_review",
            "timeline": [
                {
                    "message": "Incident detected by Camera CAM-004",
                    "status": "submitted",
                    "updated_at": now - timedelta(hours=1),
                    "updated_by": "CCTV_SYSTEM",
                },
                {
                    "message": "Alert acknowledged by Admin",
                    "status": "under_review",
                    "updated_at": now - timedelta(minutes=45),
                    "updated_by": "Admin",
                }
            ],
            "detected_at": now - timedelta(hours=1),
            "created_at": now - timedelta(hours=1),
            "updated_at": now - timedelta(minutes=45),
            "acknowledged_by": "Admin",
            "acknowledged_at": now - timedelta(minutes=45),
        },
        {
            "camera_id": "CAM-005",
            "camera_location": "Hostel Block A - Entrance",
            "incident_type": "suspicious_activity",
            "description": "Unidentified person loitering near entrance for extended period",
            "confidence_score": 0.76,
            "status": "in_progress",
            "timeline": [
                {
                    "message": "Incident detected by Camera CAM-005",
                    "status": "submitted",
                    "updated_at": now - timedelta(hours=2),
                    "updated_by": "CCTV_SYSTEM",
                },
                {
                    "message": "Security team dispatched to location",
                    "status": "in_progress",
                    "updated_at": now - timedelta(hours=1, minutes=50),
                    "updated_by": "Admin",
                }
            ],
            "detected_at": now - timedelta(hours=2),
            "created_at": now - timedelta(hours=2),
            "updated_at": now - timedelta(hours=1, minutes=50),
        },
        {
            "camera_id": "CAM-007",
            "camera_location": "Sports Complex - Basketball Court",
            "incident_type": "fighting",
            "description": "Aggressive behavior and physical contact detected",
            "confidence_score": 0.85,
            "status": "resolved",
            "timeline": [
                {
                    "message": "Incident detected by Camera CAM-007",
                    "status": "submitted",
                    "updated_at": now - timedelta(days=1),
                    "updated_by": "CCTV_SYSTEM",
                },
                {
                    "message": "Security personnel arrived at scene",
                    "status": "in_progress",
                    "updated_at": now - timedelta(days=1) + timedelta(minutes=10),
                    "updated_by": "Admin",
                },
                {
                    "message": "Situation resolved, students counseled",
                    "status": "resolved",
                    "updated_at": now - timedelta(days=1) + timedelta(minutes=30),
                    "updated_by": "Admin",
                }
            ],
            "detected_at": now - timedelta(days=1),
            "created_at": now - timedelta(days=1),
            "updated_at": now - timedelta(days=1) + timedelta(minutes=30),
        },
        {
            "camera_id": "CAM-002",
            "camera_location": "Admin Block Entrance",
            "incident_type": "vandalism",
            "description": "Property damage detected - notice board defacement",
            "confidence_score": 0.81,
            "status": "resolved",
            "timeline": [
                {
                    "message": "Incident detected by Camera CAM-002",
                    "status": "submitted",
                    "updated_at": now - timedelta(days=2),
                    "updated_by": "CCTV_SYSTEM",
                },
                {
                    "message": "Maintenance team notified",
                    "status": "in_progress",
                    "updated_at": now - timedelta(days=2) + timedelta(hours=1),
                    "updated_by": "Admin",
                },
                {
                    "message": "Damage repaired, culprits identified",
                    "status": "resolved",
                    "updated_at": now - timedelta(days=1, hours=20),
                    "updated_by": "Admin",
                }
            ],
            "detected_at": now - timedelta(days=2),
            "created_at": now - timedelta(days=2),
            "updated_at": now - timedelta(days=1, hours=20),
        },
        {
            "camera_id": "CAM-008",
            "camera_location": "Parking Area - Section B",
            "incident_type": "unauthorized_entry",
            "description": "Vehicle without valid permit detected",
            "confidence_score": 0.79,
            "status": "submitted",
            "timeline": [
                {
                    "message": "Incident detected by Camera CAM-008",
                    "status": "submitted",
                    "updated_at": now - timedelta(minutes=15),
                    "updated_by": "CCTV_SYSTEM",
                }
            ],
            "detected_at": now - timedelta(minutes=15),
            "created_at": now - timedelta(minutes=15),
            "updated_at": now - timedelta(minutes=15),
        },
    ]
    
    result = await db.cctv_alerts.insert_many(sample_alerts)
    print(f"✅ Inserted {len(result.inserted_ids)} CCTV alerts")
    
    # Print summary
    print("\n📊 CCTV Alerts Summary:")
    for alert in sample_alerts:
        print(f"  • {alert['camera_id']} ({alert['camera_location']})")
        print(f"    Type: {alert['incident_type']} | Status: {alert['status']}")
        print(f"    Confidence: {alert['confidence_score']*100:.0f}%")
    
    client.close()
    print("\n✅ CCTV seed data complete!")

if __name__ == "__main__":
    asyncio.run(seed_cctv_alerts())
