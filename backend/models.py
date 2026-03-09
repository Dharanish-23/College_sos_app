from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


# ── Enums ─────────────────────────────────────────────────────────────────────

class UserRole(str, Enum):
    student = "student"
    admin = "admin"

class SOSCategory(str, Enum):
    ragging = "ragging"
    harassment = "harassment"
    medical = "medical"
    fire = "fire"
    mental_health = "mental_health"
    accident = "accident"
    theft = "theft"
    other = "other"

class ComplaintCategory(str, Enum):
    ragging = "ragging"
    harassment = "harassment"
    discrimination = "discrimination"
    academic_misconduct = "academic_misconduct"
    facility_issue = "facility_issue"
    staff_conduct = "staff_conduct"
    financial_issue = "financial_issue"
    other = "other"

class RequestStatus(str, Enum):
    submitted = "submitted"
    under_review = "under_review"
    in_progress = "in_progress"
    resolved = "resolved"
    closed = "closed"
    rejected = "rejected"

class CCTVIncidentType(str, Enum):
    fighting = "fighting"
    large_crowd = "large_crowd"
    suspicious_activity = "suspicious_activity"
    vandalism = "vandalism"
    unauthorized_entry = "unauthorized_entry"
    other = "other"


# ── User Models ───────────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    name: str
    roll_number: str
    email: str
    password: str
    role: UserRole = UserRole.student
    department: Optional[str] = None
    year: Optional[str] = None
    hostel_block: Optional[str] = None
    phone: Optional[str] = None
    blood_group: Optional[str] = None

class UserLogin(BaseModel):
    roll_number: str
    password: str
    role: UserRole = UserRole.student

class UserResponse(BaseModel):
    id: str
    name: str
    roll_number: str
    email: str
    role: UserRole
    department: Optional[str] = None
    year: Optional[str] = None
    hostel_block: Optional[str] = None
    phone: Optional[str] = None
    blood_group: Optional[str] = None

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


# ── Status Update ─────────────────────────────────────────────────────────────

class StatusUpdate(BaseModel):
    message: str
    status: RequestStatus
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    updated_by: Optional[str] = None


# ── Media Item — stored per uploaded file ─────────────────────────────────────

class MediaItem(BaseModel):
    url: str                          # Cloudinary secure URL (playable/viewable)
    thumbnail_url: Optional[str] = None  # Poster image for videos
    public_id: Optional[str] = None   # Cloudinary public_id (for deletion later)
    resource_type: str = "image"      # "image" or "video"
    duration: Optional[float] = None  # seconds (videos only)
    file_size: Optional[int] = None   # bytes
    original_filename: Optional[str] = None
    uploaded_at: datetime = Field(default_factory=datetime.utcnow)


# ── SOS Models ────────────────────────────────────────────────────────────────

class SOSCreate(BaseModel):
    category: SOSCategory
    description: str
    location: str
    is_anonymous: bool = False
    has_video: bool = False

class SOSStatusUpdate(BaseModel):
    status: RequestStatus
    message: str

class SOSResponse(BaseModel):
    id: str
    student_id: str
    student_name: str
    roll_number: str
    department: Optional[str] = None
    category: SOSCategory
    description: str
    location: str
    is_anonymous: bool
    has_video: bool
    video_url: Optional[str] = None           # Cloudinary video URL
    video_thumbnail_url: Optional[str] = None # Auto-generated poster
    video_duration: Optional[float] = None    # seconds
    status: RequestStatus
    timeline: List[StatusUpdate]
    created_at: datetime
    updated_at: datetime


# ── Complaint Models ──────────────────────────────────────────────────────────

class ComplaintCreate(BaseModel):
    category: ComplaintCategory
    subject: str
    description: str
    location: str
    is_anonymous: bool = False
    against_person: Optional[str] = None
    media_count: int = 0
    media_types: List[str] = []

class ComplaintStatusUpdate(BaseModel):
    status: RequestStatus
    message: str

class ComplaintResponse(BaseModel):
    id: str
    student_id: str
    student_name: str
    roll_number: str
    department: Optional[str] = None
    category: ComplaintCategory
    subject: str
    description: str
    location: str
    is_anonymous: bool
    against_person: Optional[str] = None
    media_count: int
    media_types: List[str]
    media_urls: List[str] = []            # Cloudinary URLs (backward compat)
    media_items: List[MediaItem] = []     # Full rich metadata per file
    status: RequestStatus
    timeline: List[StatusUpdate]
    created_at: datetime
    updated_at: datetime


# ── Dashboard Stats ───────────────────────────────────────────────────────────

class AdminDashboardStats(BaseModel):
    total_students: int
    total_sos: int
    total_complaints: int
    total_cctv_alerts: int
    pending_sos: int
    pending_complaints: int
    pending_cctv_alerts: int
    resolved_today: int
    sos_by_category: dict
    complaints_by_category: dict
    cctv_alerts_by_type: dict
    recent_sos: List[SOSResponse]
    recent_complaints: List[ComplaintResponse]
    recent_cctv_alerts: List['CCTVAlertResponse'] = []

class StudentDashboardStats(BaseModel):
    total_sos: int
    total_complaints: int
    pending_count: int
    resolved_count: int
    recent_sos: List[SOSResponse]
    recent_complaints: List[ComplaintResponse]


# ── CCTV Alert Models ────────────────────────────────────────────────────────

class CCTVAlertCreate(BaseModel):
    camera_id: str
    camera_location: str
    incident_type: CCTVIncidentType
    description: str
    confidence_score: float = 0.85  # Simulated AI confidence
    detected_at: datetime = Field(default_factory=datetime.utcnow)

class CCTVAlertStatusUpdate(BaseModel):
    status: RequestStatus
    message: str

class CCTVAlertResponse(BaseModel):
    id: str
    camera_id: str
    camera_location: str
    incident_type: CCTVIncidentType
    description: str
    confidence_score: float
    video_url: Optional[str] = None
    video_thumbnail_url: Optional[str] = None
    video_duration: Optional[float] = None
    status: RequestStatus
    timeline: List[StatusUpdate]
    detected_at: datetime
    created_at: datetime
    updated_at: datetime
    acknowledged_by: Optional[str] = None
    acknowledged_at: Optional[datetime] = None
