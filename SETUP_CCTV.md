# Quick Setup Guide - CCTV Feature

## Step-by-Step Setup

### 1. Backend Setup

Open PowerShell/Terminal in the project root:

```powershell
# Navigate to backend
cd backend

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Seed CCTV demo data
python seed_cctv_data.py

# Start the backend server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The backend will start at: `http://localhost:8000`

API Docs available at: `http://localhost:8000/docs`

### 2. Flutter App Setup

Open a NEW PowerShell/Terminal window:

```powershell
# Navigate to project root
cd D:\college_sos_app

# Get Flutter dependencies
flutter pub get

# Run the app (Chrome/Web)
flutter run -d chrome

# OR for Android emulator
flutter run
```

### 3. Login and Test

1. **Login as Admin**:
   - Roll Number: `ADMIN001`
   - Password: `admin123`
   - Role: Admin

2. **Navigate to CCTV Tab**:
   - Click the "CCTV" icon in the bottom navigation
   - You'll see 6 pre-seeded sample alerts

3. **Test Features**:
   - Filter alerts by status
   - Click "Acknowledge" on new alerts
   - Click "Update Status" to change alert status
   - Click "Timeline" to see action history
   - Click "+" to simulate a new alert
   - Click "Upload Video" to add video evidence

## Sample CCTV Alerts (Pre-seeded)

After running `seed_cctv_data.py`, you'll have:

1. **CAM-010** - Academic Block 2
   - Type: Fighting
   - Status: Submitted (NEW)
   - Detected: 5 minutes ago

2. **CAM-004** - Cafeteria
   - Type: Large Crowd
   - Status: Under Review
   - Detected: 1 hour ago

3. **CAM-005** - Hostel Block A
   - Type: Suspicious Activity
   - Status: In Progress
   - Detected: 2 hours ago

4. **CAM-007** - Sports Complex
   - Type: Fighting
   - Status: Resolved
   - Detected: 1 day ago

5. **CAM-002** - Admin Block
   - Type: Vandalism
   - Status: Resolved
   - Detected: 2 days ago

6. **CAM-008** - Parking Area
   - Type: Unauthorized Entry
   - Status: Submitted (NEW)
   - Detected: 15 minutes ago

## Testing Workflow

### Scenario: Respond to Fighting Alert

1. **View Alert**:
   - Open CCTV tab
   - See CAM-010 alert (Fighting, Academic Block 2)
   - Status shows "New Alert" in red

2. **Acknowledge**:
   - Click "Acknowledge" button
   - Alert status changes to "Under Review" (orange)
   - Timeline updated with "Alert acknowledged by Admin"

3. **Upload Video** (Optional):
   - Click "Upload Video"
   - Select a video file from your computer
   - Video uploads to Cloudinary
   - Thumbnail appears on the card

4. **Update Status**:
   - Click "Update Status"
   - Select "In Progress"
   - Add message: "Security team dispatched to location"
   - Click "Update"

5. **Resolve**:
   - Click "Update Status" again
   - Select "Resolved"
   - Add message: "Situation resolved, students counseled"
   - Click "Update"

6. **View Timeline**:
   - Click "Timeline" button
   - See complete history of actions

## Dashboard Stats

After setup, the admin dashboard will show:

- **Total CCTV Alerts**: 6
- **Pending CCTV**: 2 (submitted + under_review + in_progress)
- **Recent CCTV Alerts**: Last 5 alerts
- **CCTV Alerts by Type**: Breakdown chart

## Simulate New Alert

1. Click "+" icon in CCTV screen app bar
2. Fill the form:
   - **Camera ID**: Select from CAM-001 to CAM-010
   - **Location**: e.g., "Library - Reading Hall"
   - **Incident Type**: Choose from dropdown
   - **Description**: e.g., "Loud argument between students"
3. Click "Simulate"
4. New alert appears at the top of the list

## API Testing (Optional)

Open `http://localhost:8000/docs` in your browser to test APIs:

### Create Alert
```json
POST /cctv/simulate-alert
{
  "camera_id": "CAM-003",
  "camera_location": "Library Ground Floor",
  "incident_type": "large_crowd",
  "description": "Unusual crowd gathering detected",
  "confidence_score": 0.88
}
```

### Get All Alerts
```
GET /cctv/alerts
```

### Get Pending Alerts
```
GET /cctv/alerts/pending
```

### Acknowledge Alert
```
PATCH /cctv/alerts/{alert_id}/acknowledge
```

### Update Status
```json
PATCH /cctv/alerts/{alert_id}/status
{
  "status": "resolved",
  "message": "Issue resolved successfully"
}
```

## Troubleshooting

### Backend Won't Start
- Check if port 8000 is already in use
- Verify MongoDB is running (check connection string in `.env`)
- Ensure virtual environment is activated

### Seed Script Fails
- Make sure backend is NOT running when seeding
- Check MongoDB connection
- Verify `config.py` has correct settings

### Flutter App Can't Connect
- Check `lib/services/api_config.dart`
- For Chrome: Use `http://localhost:8000`
- For Android emulator: Use `http://10.0.2.2:8000`
- For physical device: Use your PC's IP address

### No Alerts Showing
- Run `python seed_cctv_data.py` again
- Check backend logs for errors
- Refresh the CCTV screen

### Video Upload Fails
- Check Cloudinary credentials in `backend/.env`
- Ensure video file is < 100MB
- Check internet connection

## File Structure

New files added for CCTV feature:

```
backend/
├── routes/
│   └── cctv_routes.py          # CCTV API endpoints
├── seed_cctv_data.py            # Sample data seeder
└── models.py                    # Updated with CCTV models

lib/
├── models/
│   └── cctv_alert.dart          # CCTV alert data model
├── screens/
│   ├── admin_cctv_screen.dart   # CCTV monitoring UI
│   └── admin_dashboard.dart     # Updated with CCTV tab
└── services/
    └── api_service.dart         # Updated with CCTV methods

CCTV_FEATURE.md                  # Complete documentation
SETUP_CCTV.md                    # This file
```

## Next Steps

After testing the prototype:

1. **Demo the Feature**: Show how alerts are created and managed
2. **Collect Feedback**: Get input on UI/UX and workflow
3. **Plan Production**: Design real AI detection integration
4. **Scale Up**: Add more cameras and incident types

## Support

For issues or questions:
1. Check backend logs: Look at the terminal running uvicorn
2. Check Flutter logs: Look at the terminal running flutter
3. Review API docs: `http://localhost:8000/docs`
4. Read full documentation: `CCTV_FEATURE.md`

---

**Ready to test!** Follow the steps above and you'll have a working CCTV monitoring system in minutes.
