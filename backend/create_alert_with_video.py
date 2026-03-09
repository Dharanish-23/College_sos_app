"""
Script to create a new CCTV alert with the demo video
This creates a fresh alert and attaches your video to it
"""
import asyncio
from pathlib import Path
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient
from config import settings
from cloudinary_service import upload_video_to_cloudinary

async def create_alert_with_video():
    # Video file path
    video_path = Path(__file__).parent.parent / "WhatsApp Video 2026-03-07 at 3.24.33 PM.mp4"
    
    if not video_path.exists():
        print(f"❌ Video file not found at: {video_path}")
        return
    
    print(f"📹 Found video file: {video_path.name}")
    print(f"   Size: {video_path.stat().st_size / (1024*1024):.2f} MB")
    
    # Connect to MongoDB
    client = AsyncIOMotorClient(settings.MONGO_URI)
    db = client[settings.DB_NAME]
    
    # Read video file
    print(f"\n📤 Uploading video to Cloudinary...")
    with open(video_path, 'rb') as f:
        video_bytes = f.read()
    
    try:
        # Upload to Cloudinary first
        upload_result = await upload_video_to_cloudinary(
            video_bytes,
            folder="college_sos/cctv",
            public_id=f"cctv_demo_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}",
        )
        
        print(f"✅ Video uploaded successfully!")
        print(f"   URL: {upload_result['secure_url']}")
        if upload_result.get('thumbnail_url'):
            print(f"   Thumbnail: {upload_result['thumbnail_url']}")
        if upload_result.get('duration'):
            print(f"   Duration: {upload_result['duration']:.1f} seconds")
        
        # Create new CCTV alert with video
        now = datetime.utcnow()
        alert_doc = {
            "camera_id": "CAM-010",
            "camera_location": "Academic Block 2 - Corridor",
            "incident_type": "fighting",
            "description": "Physical altercation detected between students - DEMO VIDEO",
            "confidence_score": 0.92,
            "video_url": upload_result["secure_url"],
            "video_thumbnail_url": upload_result.get("thumbnail_url"),
            "video_duration": upload_result.get("duration"),
            "status": "submitted",
            "timeline": [
                {
                    "message": "Incident detected by Camera CAM-010 with video evidence",
                    "status": "submitted",
                    "updated_at": now,
                    "updated_by": "CCTV_SYSTEM",
                }
            ],
            "detected_at": now,
            "created_at": now,
            "updated_at": now,
        }
        
        result = await db.cctv_alerts.insert_one(alert_doc)
        alert_id = str(result.inserted_id)
        
        print(f"\n✅ New CCTV alert created!")
        print(f"   Alert ID: {alert_id}")
        print(f"   Camera: CAM-010")
        print(f"   Location: Academic Block 2 - Corridor")
        print(f"   Type: Fighting")
        print(f"   Status: Submitted (NEW)")
        print(f"   Video: Attached")
        
        print(f"\n🎉 Success! Your demo video is now in the system")
        print(f"   Open the CCTV monitoring screen to see it")
        print(f"   The alert will appear at the top with a video thumbnail")
        
    except Exception as e:
        print(f"\n❌ Failed: {e}")
        print("\nPlease check:")
        print("1. Cloudinary credentials in backend/.env")
        print("2. Internet connection")
        print("3. MongoDB is running")
    
    client.close()

if __name__ == "__main__":
    print("=" * 60)
    print("Create CCTV Alert with Demo Video")
    print("=" * 60)
    asyncio.run(create_alert_with_video())
