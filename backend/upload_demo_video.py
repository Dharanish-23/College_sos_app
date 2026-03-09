"""
Script to upload the demo video to a CCTV alert
This will attach the WhatsApp video to one of the seeded alerts
"""
import asyncio
import sys
from pathlib import Path
from motor.motor_asyncio import AsyncIOMotorClient
from config import settings
from cloudinary_service import upload_video_to_cloudinary

async def upload_demo_video():
    # Video file path (relative to project root)
    video_path = Path(__file__).parent.parent / "WhatsApp Video 2026-03-07 at 3.24.33 PM.mp4"
    
    if not video_path.exists():
        print(f"❌ Video file not found at: {video_path}")
        print("Please make sure the video file is in the project root directory")
        return
    
    print(f"📹 Found video file: {video_path.name}")
    print(f"   Size: {video_path.stat().st_size / (1024*1024):.2f} MB")
    
    # Connect to MongoDB
    client = AsyncIOMotorClient(settings.MONGO_URI)
    db = client[settings.DB_NAME]
    
    # Find the first fighting alert (CAM-010)
    alert = await db.cctv_alerts.find_one({"camera_id": "CAM-010", "incident_type": "fighting"})
    
    if not alert:
        print("❌ No fighting alert found. Please run seed_cctv_data.py first")
        client.close()
        return
    
    alert_id = str(alert["_id"])
    print(f"\n📍 Found alert:")
    print(f"   Camera: {alert['camera_id']}")
    print(f"   Location: {alert['camera_location']}")
    print(f"   Type: {alert['incident_type']}")
    print(f"   Alert ID: {alert_id}")
    
    # Read video file
    print(f"\n📤 Uploading video to Cloudinary...")
    with open(video_path, 'rb') as f:
        video_bytes = f.read()
    
    try:
        # Upload to Cloudinary
        upload_result = await upload_video_to_cloudinary(
            video_bytes,
            folder="college_sos/cctv",
            public_id=f"cctv_{alert_id}_demo",
        )
        
        print(f"✅ Video uploaded successfully!")
        print(f"   URL: {upload_result['secure_url']}")
        if upload_result.get('thumbnail_url'):
            print(f"   Thumbnail: {upload_result['thumbnail_url']}")
        if upload_result.get('duration'):
            print(f"   Duration: {upload_result['duration']:.1f} seconds")
        
        # Update the alert with video URL
        from datetime import datetime
        await db.cctv_alerts.update_one(
            {"_id": alert["_id"]},
            {
                "$set": {
                    "video_url": upload_result["secure_url"],
                    "video_thumbnail_url": upload_result.get("thumbnail_url"),
                    "video_duration": upload_result.get("duration"),
                    "updated_at": datetime.utcnow(),
                }
            },
        )
        
        print(f"\n✅ Alert updated with video!")
        print(f"\n🎉 Demo video is now attached to the fighting alert at CAM-010")
        print(f"   You can view it in the CCTV monitoring screen")
        
    except Exception as e:
        print(f"\n❌ Upload failed: {e}")
        print("\nPlease check:")
        print("1. Cloudinary credentials in backend/.env")
        print("2. Internet connection")
        print("3. Video file is not corrupted")
    
    client.close()

if __name__ == "__main__":
    print("=" * 60)
    print("CCTV Demo Video Upload Script")
    print("=" * 60)
    asyncio.run(upload_demo_video())
