# Using Your Demo Video with CCTV Feature

## 📹 Video File Detected

Your video: `WhatsApp Video 2026-03-07 at 3.24.33 PM.mp4`

## 🎯 Two Ways to Use Your Video

### Option 1: Attach to Existing Alert (Recommended)

This will add your video to the pre-seeded fighting alert at CAM-010.

```powershell
cd backend
.\venv\Scripts\Activate.ps1
python upload_demo_video.py
```

**What it does:**
- Uploads your video to Cloudinary
- Attaches it to the CAM-010 fighting alert
- Generates thumbnail automatically
- Updates the alert in database

**Result:**
- Open CCTV tab → See CAM-010 alert with video thumbnail
- Click thumbnail to play your video

---

### Option 2: Create New Alert with Video

This creates a brand new alert specifically for your video.

```powershell
cd backend
.\venv\Scripts\Activate.ps1
python create_alert_with_video.py
```

**What it does:**
- Uploads your video to Cloudinary
- Creates a NEW fighting alert at CAM-010
- Attaches video with thumbnail
- Adds to database as "submitted" status

**Result:**
- New alert appears at top of CCTV list
- Shows as "NEW" with red indicator
- Video thumbnail ready to play

---

## 🚀 Complete Demo Workflow

### Step 1: Setup Backend
```powershell
cd backend
.\venv\Scripts\Activate.ps1

# Seed sample alerts (if not done)
python seed_cctv_data.py

# Upload your video (choose one option)
python create_alert_with_video.py
# OR
python upload_demo_video.py

# Start server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Step 2: Start Flutter App
```powershell
# New terminal
flutter pub get
flutter run -d chrome
```

### Step 3: View in App
1. Login: `ADMIN001` / `admin123`
2. Click **CCTV** tab
3. See your video alert at the top
4. Click the video thumbnail
5. Video plays in browser

---

## 🎬 Demo Presentation Flow

### 1. Show the Alert
- Point out the camera ID (CAM-010)
- Highlight the location (Academic Block 2)
- Show the incident type (Fighting)
- Note the confidence score (92%)
- Show the timestamp

### 2. Play the Video
- Click the video thumbnail
- Video opens in new tab/browser
- Cloudinary CDN delivers it smoothly
- Thumbnail auto-generated

### 3. Demonstrate Admin Actions

**Acknowledge:**
- Click "Acknowledge" button
- Status changes to "Under Review" (orange)
- Timeline updated

**Update Status:**
- Click "Update Status"
- Select "In Progress"
- Add message: "Security team dispatched to Academic Block 2"
- Click Update

**View Timeline:**
- Click "Timeline" button
- Show complete history:
  - Detected by CCTV system
  - Acknowledged by admin
  - Status updates with messages

**Resolve:**
- Click "Update Status" again
- Select "Resolved"
- Add message: "Situation resolved, students counseled, parents notified"
- Click Update

### 4. Show Dashboard
- Go back to Dashboard tab
- Show CCTV statistics:
  - Total CCTV Alerts
  - Pending CCTV Alerts
  - Recent alerts list

---

## 📊 What Makes This Impressive

### For Your Prototype Demo:

1. **Real Video Evidence**: Not just text alerts, actual video footage
2. **Automatic Detection**: Simulates AI detection with confidence scores
3. **Location Tracking**: Exact camera and location details
4. **Complete Workflow**: From detection → acknowledgment → resolution
5. **Audit Trail**: Full timeline of all actions taken
6. **Cloud Storage**: Video hosted on Cloudinary CDN
7. **Responsive UI**: Beautiful, professional interface
8. **Real-time Updates**: Status changes reflect immediately

### Technical Highlights:

- ✅ Video upload to cloud (Cloudinary)
- ✅ Automatic thumbnail generation
- ✅ MongoDB document storage
- ✅ RESTful API architecture
- ✅ JWT authentication
- ✅ Status workflow management
- ✅ Timeline/audit logging
- ✅ Responsive Flutter UI
- ✅ Cross-platform (Web, Mobile, Desktop)

---

## 🎤 Demo Script

**"Let me show you our CCTV monitoring feature..."**

1. **"The system has 10 cameras across campus monitoring 24/7"**
   - Show camera list (CAM-001 to CAM-010)

2. **"When an incident is detected, an alert is automatically created"**
   - Show the alert with your video
   - Point out: camera ID, location, incident type, confidence score

3. **"The system records video evidence and stores it securely"**
   - Click video thumbnail
   - Video plays from Cloudinary CDN

4. **"Admins can respond immediately"**
   - Acknowledge the alert
   - Update status with messages
   - Show timeline of actions

5. **"Everything is tracked for accountability"**
   - Show complete timeline
   - All actions logged with timestamps

6. **"Dashboard provides real-time overview"**
   - Show CCTV statistics
   - Pending alerts highlighted

**"In production, this would connect to real AI detection, but the architecture is ready for that integration."**

---

## 🔧 Troubleshooting

### Video Upload Fails

**Check Cloudinary credentials:**
```powershell
# Edit backend/.env
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

**Get free Cloudinary account:**
1. Go to https://cloudinary.com
2. Sign up (free tier: 25GB storage)
3. Copy credentials from dashboard
4. Paste into backend/.env

### Video Not Showing in App

1. **Refresh the CCTV screen**: Pull down to refresh
2. **Check backend logs**: Look for upload success message
3. **Verify database**: Check if video_url is saved
4. **Check browser console**: Look for any errors

### Video Won't Play

1. **Check URL**: Should be `https://res.cloudinary.com/...`
2. **Try different browser**: Chrome works best
3. **Check internet**: Video streams from Cloudinary
4. **Verify upload**: Re-run upload script

---

## 📱 Alternative: Manual Upload via UI

If scripts don't work, you can upload via the app:

1. Start backend and Flutter app
2. Login as admin
3. Go to CCTV tab
4. Find any alert WITHOUT video
5. Click "Upload Video" button
6. Select your video file
7. Wait for upload to complete

---

## 🎯 Quick Commands Reference

```powershell
# Seed sample alerts
cd backend
python seed_cctv_data.py

# Upload your video to existing alert
python upload_demo_video.py

# Create new alert with your video
python create_alert_with_video.py

# Start backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Start Flutter (new terminal)
flutter run -d chrome
```

---

## 📸 Expected Result

After running the upload script, you should see:

```
============================================================
CCTV Demo Video Upload Script
============================================================
📹 Found video file: WhatsApp Video 2026-03-07 at 3.24.33 PM.mp4
   Size: X.XX MB

📍 Found alert:
   Camera: CAM-010
   Location: Academic Block 2 - Corridor
   Type: fighting
   Alert ID: xxxxx

📤 Uploading video to Cloudinary...
✅ Video uploaded successfully!
   URL: https://res.cloudinary.com/...
   Thumbnail: https://res.cloudinary.com/.../thumbnail.jpg
   Duration: XX.X seconds

✅ Alert updated with video!

🎉 Demo video is now attached to the fighting alert at CAM-010
   You can view it in the CCTV monitoring screen
```

---

## 🎓 For Your Presentation

**Key Points to Mention:**

1. **"This is a prototype, so we're simulating the AI detection"**
   - In production, this would use YOLOv8 or similar
   - Real-time video stream processing
   - Automatic incident detection

2. **"The architecture is production-ready"**
   - RESTful API design
   - Cloud storage (Cloudinary)
   - Scalable database (MongoDB)
   - Modern frontend (Flutter)

3. **"Complete audit trail for accountability"**
   - Every action logged
   - Timestamps recorded
   - Admin names tracked

4. **"Enhances campus safety significantly"**
   - Immediate incident awareness
   - Quick response capability
   - Video evidence preservation
   - Location tracking

---

## ✅ Checklist Before Demo

- [ ] Backend running (`uvicorn main:app --reload`)
- [ ] Sample alerts seeded (`python seed_cctv_data.py`)
- [ ] Your video uploaded (`python create_alert_with_video.py`)
- [ ] Flutter app running (`flutter run -d chrome`)
- [ ] Logged in as admin (ADMIN001 / admin123)
- [ ] CCTV tab accessible
- [ ] Video thumbnail visible
- [ ] Video plays when clicked
- [ ] Dashboard shows CCTV stats

---

**You're all set! Your demo video is ready to showcase the CCTV monitoring feature.** 🎉
