# CCTV Feature - Quick Start Guide

## 🚀 Start in 3 Steps

### Step 1: Start Backend (Terminal 1)
```powershell
cd backend
.\venv\Scripts\Activate.ps1
python seed_cctv_data.py
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Step 2: Start Flutter (Terminal 2)
```powershell
flutter pub get
flutter run -d chrome
```

### Step 3: Test
1. Login: `ADMIN001` / `admin123`
2. Click **CCTV** tab (bottom navigation)
3. See 6 pre-loaded alerts
4. Click **+** to simulate new alert
5. Test acknowledge, update status, upload video

## 📋 What You'll See

### Pre-loaded Alerts
- **CAM-010** - Fighting (NEW) - 5 min ago
- **CAM-004** - Large Crowd (Under Review) - 1 hr ago
- **CAM-005** - Suspicious Activity (In Progress) - 2 hrs ago
- **CAM-007** - Fighting (Resolved) - 1 day ago
- **CAM-002** - Vandalism (Resolved) - 2 days ago
- **CAM-008** - Unauthorized Entry (NEW) - 15 min ago

### Dashboard Stats
- Total CCTV Alerts: 6
- Pending CCTV: 3
- Recent alerts shown

## 🎯 Quick Test Workflow

1. **View Alert**: Click any alert card
2. **Acknowledge**: Click "Acknowledge" button (for NEW alerts)
3. **Update Status**: 
   - Click "Update Status"
   - Select status (In Progress/Resolved)
   - Add message
   - Click Update
4. **View Timeline**: Click "Timeline" to see history
5. **Upload Video**: Click "Upload Video" to add evidence
6. **Simulate New**: Click "+" to create test alert

## 📚 Documentation

- **Full Details**: `CCTV_FEATURE.md`
- **Setup Guide**: `SETUP_CCTV.md`
- **Implementation**: `IMPLEMENTATION_SUMMARY.md`
- **API Docs**: http://localhost:8000/docs

## 🔧 Troubleshooting

### Backend won't start
```powershell
# Check if port 8000 is in use
netstat -ano | findstr :8000
```

### No alerts showing
```powershell
cd backend
python seed_cctv_data.py
```

### Flutter errors
```powershell
flutter clean
flutter pub get
```

## 📞 Need Help?

Check the detailed documentation files or backend logs for errors.

---

**That's it!** You're ready to demo the CCTV monitoring feature. 🎉
