"""
Quick test script to verify video upload functionality
Tests Cloudinary connection and video processing
"""
import asyncio
from pathlib import Path
from cloudinary_service import upload_video_to_cloudinary

async def test_upload():
    video_path = Path(__file__).parent.parent / "WhatsApp Video 2026-03-07 at 3.24.33 PM.mp4"
    
    print("=" * 60)
    print("CCTV Video Upload Test")
    print("=" * 60)
    
    # Check if video exists
    if not video_path.exists():
        print("❌ Video file not found!")
        print(f"   Expected at: {video_path}")
        print("\nPlease ensure the video file is in the project root directory")
        return False
    
    print(f"✅ Video file found: {video_path.name}")
    file_size_mb = video_path.stat().st_size / (1024 * 1024)
    print(f"   Size: {file_size_mb:.2f} MB")
    
    if file_size_mb > 100:
        print("⚠️  Warning: Video is larger than 100MB")
        print("   Upload may take a while...")
    
    # Check Cloudinary config
    print("\n📋 Checking Cloudinary configuration...")
    try:
        from config import settings
        if not settings.CLOUDINARY_CLOUD_NAME:
            print("❌ CLOUDINARY_CLOUD_NAME not set in .env")
            return False
        if not settings.CLOUDINARY_API_KEY:
            print("❌ CLOUDINARY_API_KEY not set in .env")
            return False
        if not settings.CLOUDINARY_API_SECRET:
            print("❌ CLOUDINARY_API_SECRET not set in .env")
            return False
        
        print(f"✅ Cloud Name: {settings.CLOUDINARY_CLOUD_NAME}")
        print(f"✅ API Key: {settings.CLOUDINARY_API_KEY[:4]}...{settings.CLOUDINARY_API_KEY[-4:]}")
        print("✅ API Secret: ****")
        
    except Exception as e:
        print(f"❌ Configuration error: {e}")
        print("\nPlease check backend/.env file")
        return False
    
    # Test upload
    print("\n📤 Testing video upload to Cloudinary...")
    print("   This may take a minute depending on file size...")
    
    try:
        with open(video_path, 'rb') as f:
            video_bytes = f.read()
        
        result = await upload_video_to_cloudinary(
            video_bytes,
            folder="college_sos/cctv/test",
            public_id="test_upload",
        )
        
        print("\n✅ Upload successful!")
        print(f"\n📊 Upload Details:")
        print(f"   URL: {result['secure_url']}")
        if result.get('thumbnail_url'):
            print(f"   Thumbnail: {result['thumbnail_url']}")
        if result.get('duration'):
            print(f"   Duration: {result['duration']:.1f} seconds")
        if result.get('format'):
            print(f"   Format: {result['format']}")
        if result.get('width') and result.get('height'):
            print(f"   Resolution: {result['width']}x{result['height']}")
        
        print("\n🎉 Test passed! Video upload is working correctly.")
        print("\nYou can now run:")
        print("   python create_alert_with_video.py")
        print("   OR")
        print("   python upload_demo_video.py")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Upload failed: {e}")
        print("\n🔧 Troubleshooting:")
        print("1. Check Cloudinary credentials in backend/.env")
        print("2. Verify internet connection")
        print("3. Ensure video file is not corrupted")
        print("4. Try with a smaller video file first")
        print("\n📚 Get Cloudinary credentials:")
        print("   1. Go to https://cloudinary.com")
        print("   2. Sign up for free account")
        print("   3. Copy credentials from dashboard")
        print("   4. Add to backend/.env file")
        return False

if __name__ == "__main__":
    success = asyncio.run(test_upload())
    exit(0 if success else 1)
