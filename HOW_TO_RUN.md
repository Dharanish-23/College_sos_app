# College SOS App — Setup & Run Guide

## Architecture

```
college_sos_app/
├── backend/          ← FastAPI + MongoDB (Python)
└── lib/              ← Flutter App (Dart)
```

---

## 1. Backend Setup (FastAPI)

### Prerequisites
- Python 3.10+

### Steps

```powershell
cd D:\college_sos_app\backend

# Activate virtual environment (already created)
.\venv\Scripts\Activate.ps1

# Install dependencies (fixed versions)
pip install -r requirements.txt

# Seed the database (run ONCE to populate demo data)
python seed_data.py

# Start the server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be live at: **http://localhost:8000**
API Docs (Swagger): **http://localhost:8000/docs**

> If you get a script execution policy error, run this first:
> `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

---

## 2. Flutter App Setup

### Configure API URL

Edit `lib/services/api_config.dart`:

```dart
// For Chrome/web or iOS simulator:
const String kBaseUrl = 'http://localhost:8000';

// For Android emulator:
const String kBaseUrl = 'http://10.0.2.2:8000';

// For physical Android device (use your machine's local IP):
const String kBaseUrl = 'http://192.168.x.x:8000';
```

### Run

```powershell
cd D:\college_sos_app
flutter pub get
flutter run -d chrome        # for web
# or
flutter run                  # for connected device/emulator
```

---

## 3. Login Credentials

| Role    | Roll Number  | Password  |
|---------|--------------|-----------|
| Student | 2023CS001    | pass123   |
| Student | 2023CS002    | pass456   |
| Student | 2022EC010    | pass789   |
| Student | 2023ME005    | pass321   |
| Student | 2024CS012    | pass654   |
| Admin   | ADMIN001     | admin123  |

---

## 4. Features

### Student Dashboard
- 🆘 **Raise SOS** — Emergency alerts stored in MongoDB, visible to admin instantly
- 📋 **File Complaint** — Submit complaints with category, description, attachments
- 📊 **Track Status** — Real-time status & full timeline from DB for own SOS/complaints
- 🔐 **Real Login** — JWT auth against MongoDB

### Admin Dashboard
- 📊 **Live Analytics** — Total students, SOS, complaints, resolved today (from DB)
- 🆘 **Manage SOS** — View all SOS alerts, filter by status, update with message
- 📋 **Manage Complaints** — View all complaints, respond, update status
- 👥 **Student Directory** — All registered students with full details
- 🔴 **Pending Alerts** — Critical pending SOS/complaints requiring action

---

## 5. MongoDB Collections

| Collection      | Description                            |
|-----------------|----------------------------------------|
| `users`         | Students + Admin accounts              |
| `sos_requests`  | All SOS alerts with timeline           |
| `complaints`    | All complaints with timeline           |

---

## 6. API Endpoints

| Method | Endpoint                      | Description              |
|--------|-------------------------------|--------------------------|
| POST   | /auth/login                   | Login (get JWT token)    |
| GET    | /auth/me                      | Get current user         |
| POST   | /auth/register                | Register new user        |
| POST   | /sos/                         | Submit SOS (student)     |
| GET    | /sos/my                       | My SOS list (student)    |
| GET    | /sos/admin/all                | All SOS (admin)          |
| PATCH  | /sos/admin/{id}/status        | Update SOS status        |
| POST   | /complaints/                  | Submit complaint         |
| GET    | /complaints/my                | My complaints (student)  |
| GET    | /complaints/admin/all         | All complaints (admin)   |
| PATCH  | /complaints/admin/{id}/status | Update complaint status  |
| GET    | /dashboard/student            | Student dashboard data   |
| GET    | /dashboard/admin              | Admin dashboard data     |
| GET    | /admin/students               | All students list        |
