"""
cloudinary_service.py
Handles all file uploads to Cloudinary.
Videos go to college_sos/sos/   (resource_type="video")
Images go to college_sos/complaints/  (resource_type="image")
Videos inside complaints go to college_sos/complaint_videos/ (resource_type="video")
"""
import asyncio
from functools import partial
import cloudinary
import cloudinary.uploader
from config import settings
import io

# Configure once at import time
cloudinary.config(
    cloud_name=settings.CLOUDINARY_CLOUD_NAME,
    api_key=settings.CLOUDINARY_API_KEY,
    api_secret=settings.CLOUDINARY_API_SECRET,
    secure=True,
)

# ── Upload helpers ─────────────────────────────────────────────────────────────

async def upload_sos_video(file_bytes: bytes, filename: str) -> dict:
    """
    Upload SOS evidence video to Cloudinary.
    Returns dict with: url, public_id, duration, format, resource_type
    """
    loop = asyncio.get_event_loop()
    result = await loop.run_in_executor(
        None,
        partial(
            cloudinary.uploader.upload,
            file_bytes,
            folder="college_sos/sos",
            resource_type="video",
            public_id=_stem(filename),
            overwrite=False,
            eager=[{"format": "jpg", "transformation": [{"width": 400, "crop": "scale"}]}],
            eager_async=True,
        )
    )
    return {
        "url": result["secure_url"],
        "public_id": result["public_id"],
        "thumbnail_url": result.get("eager", [{}])[0].get("secure_url", ""),
        "duration": result.get("duration"),
        "format": result.get("format"),
        "resource_type": "video",
        "bytes": result.get("bytes"),
    }


async def upload_complaint_image(file_bytes: bytes, filename: str) -> dict:
    """
    Upload complaint photo to Cloudinary.
    Returns dict with: url, public_id
    """
    loop = asyncio.get_event_loop()
    result = await loop.run_in_executor(
        None,
        partial(
            cloudinary.uploader.upload,
            file_bytes,
            folder="college_sos/complaints/images",
            resource_type="image",
            public_id=_stem(filename),
            overwrite=False,
            transformation=[{"quality": "auto", "fetch_format": "auto"}],
        )
    )
    return {
        "url": result["secure_url"],
        "public_id": result["public_id"],
        "thumbnail_url": result["secure_url"],
        "resource_type": "image",
        "bytes": result.get("bytes"),
    }


async def upload_complaint_video(file_bytes: bytes, filename: str) -> dict:
    """
    Upload complaint video evidence to Cloudinary.
    Returns dict with: url, public_id, duration
    """
    loop = asyncio.get_event_loop()
    result = await loop.run_in_executor(
        None,
        partial(
            cloudinary.uploader.upload,
            file_bytes,
            folder="college_sos/complaints/videos",
            resource_type="video",
            public_id=_stem(filename),
            overwrite=False,
            eager=[{"format": "jpg", "transformation": [{"width": 400, "crop": "scale"}]}],
            eager_async=True,
        )
    )
    return {
        "url": result["secure_url"],
        "public_id": result["public_id"],
        "thumbnail_url": result.get("eager", [{}])[0].get("secure_url", ""),
        "duration": result.get("duration"),
        "format": result.get("format"),
        "resource_type": "video",
        "bytes": result.get("bytes"),
    }


def _stem(filename: str) -> str:
    """Strip extension from filename to use as Cloudinary public_id stem."""
    import os, uuid
    name = os.path.splitext(filename)[0] if filename else ""
    # Make safe + unique
    safe = "".join(c if c.isalnum() or c in "-_" else "_" for c in name)
    return f"{safe}_{uuid.uuid4().hex[:8]}" if safe else uuid.uuid4().hex


async def upload_video_to_cloudinary(
    file_bytes: bytes,
    folder: str = "college_sos/cctv",
    public_id: str = None,
) -> dict:
    """
    Generic video upload to Cloudinary for CCTV footage.
    Returns dict with: secure_url, public_id, thumbnail_url, duration, format
    """
    loop = asyncio.get_event_loop()
    
    upload_params = {
        "folder": folder,
        "resource_type": "video",
        "overwrite": False,
        "eager": [{"format": "jpg", "transformation": [{"width": 400, "crop": "scale"}]}],
        "eager_async": True,
    }
    
    if public_id:
        upload_params["public_id"] = public_id
    
    result = await loop.run_in_executor(
        None,
        partial(
            cloudinary.uploader.upload,
            file_bytes,
            **upload_params
        )
    )
    
    return {
        "secure_url": result["secure_url"],
        "public_id": result["public_id"],
        "thumbnail_url": result.get("eager", [{}])[0].get("secure_url", ""),
        "duration": result.get("duration"),
        "format": result.get("format"),
        "width": result.get("width"),
        "height": result.get("height"),
        "resource_type": "video",
        "bytes": result.get("bytes"),
    }
