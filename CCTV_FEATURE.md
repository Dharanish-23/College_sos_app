# CCTV Monitoring Feature - Documentation

## Overview

The CCTV Monitoring feature adds automated incident detection and alerting to the College SOS App. This feature allows the system to detect incidents (fighting, large crowds, suspicious activity, etc.) from CCTV cameras and automatically alert administrators with location details and video evidence.

## Feature Description

### What It Does

- **Automated Incident Detection**: CCTV cameras continuously monitor campus areas
- **Incident Types Detected**:
  - Fighting between students
  - Large crowd gatherings (50+ people)
  - Suspicious activity
  - Vandalism
  - Unauthorized entry
  - Other incidents

- **Automatic Alerts**: When an incident is detected, the system:
  - Records the video footage
  - Saves it to the database (Cloudinary CDN)
  - Alerts admin with:
    - Camera ID (e.g., CAM-010)
    - Exact location (e.g., "Academic Block 2 - Corridor")
    - Incident type
    - Confidence score (AI detection confidence)
    - Video evidence with thumbnail
    - Timestamp

- **Admin Response**: Admins can:
  - View all CCTV alerts in real-time
  - See pending alerts requiring attention
  - Acknowledge alerts
  - Update status (Under Review → In Progress → Resolved)
  - Add response messages
  - View complete timeline of actions taken
  - Upload additional video evidence

## Prototype Implementation

Since this is a prototype and we don't have time to train an AI model for real-time detection, the feature is implemented as a **simulation system**:

### How the Prototype Works

1. **Simulate Alert**: Admin can manually create a CCTV alert by:
   - Selecting a camera (CAM-001 to CAM-010)
   - Choosing location
   - Selecting incident type
   - Adding description
   - System assigns confidence score (85-95%)

2. **Upload Video**: After creating an alert, admin can:
   - Upload a pre-recorded video showing the incident
   - Video is stored in Cloudinary CDN
   - Thumbnail is auto-generated
   - Video URL is saved with the alert

3. **Demo Data**: Sample alerts are pre-seeded to demonstrate the feature

## Technical Implementation

### Backend (Python/FastAPI)

#### New Models (`backend/models.py`)

```python
class CCTVIncidentType(str, Enum):
    fighting = "fighting"
    large_crowd = "large_crowd"
    suspicious_activity = "suspicious_activity"
    vandalism = "vandalism"
    unauthorized_entry = "unauthorized_entry"
    other = "other"

class CCTVAlertCreate(BaseModel):
    camera_id: str
    camera_location: str
    incident_type: CCTVIncidentType
    description: str
    confidence_score: float = 0.85

class CCTVAlertResponse(BaseModel):
    id: str
    camera_id: str
    camera_location: str
    incident_type: CCTVIncidentType
    description: str
    confidence_score: float
    video_url: Optional[str]
    video_thumbnail_url: Optional[str]
    status: RequestStatus
    timeline: List[StatusUpdate]
    detected_at: datetime
    acknowledged_by: Optional[str]
    acknowledged_at: Optional[datetime]
```

#### New API Endpoints (`backend/routes/cctv_routes.py`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/cctv/simulate-alert` | Create a simulated CCTV alert |
| POST | `/cctv/upload-alert-video/{alert_id}` | Upload video for an alert |
| GET | `/cctv/alerts` | Get all CCTV alerts (with filters) |
| GET | `/cctv/alerts/pending` | Get pending alerts |
| GET | `/cctv/alerts/{alert_id}` | Get specific alert details |
| PATCH | `/cctv/alerts/{alert_id}/acknowledge` | Acknowledge an alert |
| PATCH | `/cctv/alerts/{alert_id}/status` | Update alert status |
| GET | `/cctv/cameras/list` | Get list of all cameras |

#### Database Collection

New MongoDB collection: `cctv_alerts`

Indexes:
- `camera_id`
- `status`
- `detected_at`
- `incident_type`

### Frontend (Flutter/Dart)

#### New Files

1. **`lib/models/cctv_alert.dart`**: Data model for CCTV alerts
2. **`lib/screens/admin_cctv_screen.dart`**: Admin UI for CCTV monitoring

#### Updated Files

1. **`lib/screens/admin_dashboard.dart`**: Added CCTV tab and stats
2. **`lib/services/api_service.dart`**: Added CCTV API methods
3. **`backend/main.py`**: Registered CCTV routes
4. **`backend/database.py`**: Added CCTV indexes
5. **`backend/routes/dashboard_routes.py`**: Added CCTV stats

#### UI Features

- **Filter by Status**: All, New, Under Review, In Progress, Resolved
- **Alert Cards**: Show camera ID, location, incident type, confidence score
- **Video Playback**: Click thumbnail to play video in browser
- **Action Buttons**:
  - Acknowledge (for new alerts)
  - Update Status
  - Upload Video
  - View Timeline
- **Timeline View**: Complete history of actions taken on each alert

## Setup Instructions

### 1. Backend Setup

```bash
cd backend

# Install dependencies (if not already done)
pip install -r requirements.txt

# Seed sample CCTV alerts
python seed_cctv_data.py

# Start the server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Flutter Setup

```bash
cd college_sos_app

# Get dependencies
flutter pub get

# Run the app
flutter run -d chrome  # or your device
```

### 3. Access CCTV Monitoring

1. Login as admin:
   - Roll Number: `ADMIN001`
   - Password: `admin123`

2. Navigate to the **CCTV** tab in the bottom navigation

3. You'll see pre-seeded sample alerts

## Usage Guide

### For Admins

#### View CCTV Alerts

1. Open the CCTV tab
2. See all alerts with status indicators
3. Filter by status using chips at the top

#### Simulate a New Alert (Prototype Feature)

1. Click the "+" icon in the app bar
2. Fill in the form:
   - Select Camera ID (CAM-001 to CAM-010)
   - Enter location
   - Choose incident type
   - Add description
3. Click "Simulate"
4. Alert appears in the list

#### Upload Video Evidence

1. Find the alert in the list
2. Click "Upload Video" button
3. Select a video file from your device
4. Video uploads to Cloudinary
5. Thumbnail appears on the alert card

#### Respond to Alert

1. Click "Acknowledge" to mark as seen
2. Click "Update Status" to change status:
   - Under Review
   - In Progress
   - Resolved
   - Closed
3. Add a message explaining the action taken

#### View Timeline

1. Click "Timeline" button on any alert
2. See complete history:
   - When detected
   - Who acknowledged
   - Status changes
   - Admin responses

## Camera Locations (Prototype)

The system includes 10 simulated cameras:

| Camera ID | Location |
|-----------|----------|
| CAM-001 | Main Gate |
| CAM-002 | Admin Block Entrance |
| CAM-003 | Library Ground Floor |
| CAM-004 | Cafeteria |
| CAM-005 | Hostel Block A |
| CAM-006 | Hostel Block B |
| CAM-007 | Sports Complex |
| CAM-008 | Parking Area |
| CAM-009 | Academic Block 1 |
| CAM-010 | Academic Block 2 |

## Dashboard Integration

The admin dashboard now shows:

- **Total CCTV Alerts**: Count of all alerts
- **Pending CCTV**: Alerts needing attention
- **Recent CCTV Alerts**: Last 5 alerts
- **Alerts by Type**: Breakdown by incident type

## Future Enhancements (Production)

For a production system, you would add:

1. **Real AI Detection**:
   - Train YOLOv8 or similar model
   - Integrate with actual CCTV streams
   - Real-time processing pipeline

2. **Live Streaming**:
   - View live camera feeds
   - Instant notifications

3. **Advanced Analytics**:
   - Heatmaps of incidents
   - Pattern detection
   - Predictive alerts

4. **Mobile Push Notifications**:
   - Instant alerts to admin phones
   - Critical incident escalation

5. **Integration with Security Systems**:
   - Automatic door locks
   - Siren activation
   - Emergency services notification

## Testing the Feature

### Test Scenario 1: Fighting Detected

1. Simulate alert:
   - Camera: CAM-010
   - Location: Academic Block 2
   - Type: Fighting
   - Description: "Physical altercation between 2 students"

2. Upload a video showing a fight

3. Admin acknowledges → Status: Under Review

4. Admin dispatches security → Status: In Progress

5. Situation resolved → Status: Resolved

### Test Scenario 2: Large Crowd

1. Simulate alert:
   - Camera: CAM-004
   - Location: Cafeteria
   - Type: Large Crowd
   - Description: "Unusual gathering of 50+ students"

2. Upload video of crowd

3. Admin investigates → finds it's a peaceful event

4. Mark as Closed with message: "Authorized event"

## API Testing

Use the Swagger docs at `http://localhost:8000/docs` to test:

1. POST `/cctv/simulate-alert` - Create alert
2. POST `/cctv/upload-alert-video/{id}` - Upload video
3. GET `/cctv/alerts` - List all alerts
4. PATCH `/cctv/alerts/{id}/acknowledge` - Acknowledge
5. PATCH `/cctv/alerts/{id}/status` - Update status

## Troubleshooting

### Video Upload Fails

- Check Cloudinary credentials in `backend/.env`
- Ensure video file is not too large (< 100MB)
- Verify internet connection

### Alerts Not Showing

- Run `python seed_cctv_data.py` to add sample data
- Check MongoDB connection
- Verify backend is running

### Dashboard Stats Not Updated

- Refresh the dashboard
- Check backend logs for errors
- Verify database indexes are created

## Conclusion

This CCTV monitoring feature provides a complete prototype of automated incident detection and response. While it uses simulated alerts for demonstration, the architecture is designed to easily integrate with real AI detection systems in production.

The feature enhances campus safety by:
- Providing real-time incident awareness
- Enabling quick admin response
- Maintaining complete audit trails
- Storing video evidence securely
- Tracking resolution of incidents

For questions or issues, check the backend logs and API documentation at `/docs`.
