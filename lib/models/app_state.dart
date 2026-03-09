import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

/// Central in-memory state for the app.
/// In a real app this would be backed by a database / REST API.
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._();
  factory AppState() => _instance;
  AppState._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  Student? _currentStudent;
  Student? get currentStudent => _currentStudent;
  bool get isLoggedIn => _currentStudent != null;

  // Dummy credential store:  rollNumber -> password
  static const Map<String, String> _credentials = {
    '2023CS001': 'pass123',
    '2023CS002': 'pass456',
    '2022EC010': 'pass789',
  };

  static final Map<String, Student> _studentDb = {
    '2023CS001': const Student(
      id: 's1', name: 'Arjun Kumar', rollNumber: '2023CS001',
      email: '2023cs001@college.edu', department: 'Computer Science',
      year: '3rd Year', hostelBlock: 'Block C, Room 204',
      phone: '+91-98765-43210', bloodGroup: 'B+',
    ),
    '2023CS002': const Student(
      id: 's2', name: 'Priya Sharma', rollNumber: '2023CS002',
      email: '2023cs002@college.edu', department: 'Computer Science',
      year: '3rd Year', hostelBlock: 'Block A, Room 102',
      phone: '+91-98765-11111', bloodGroup: 'O+',
    ),
    '2022EC010': const Student(
      id: 's3', name: 'Ravi Patel', rollNumber: '2022EC010',
      email: '2022ec010@college.edu', department: 'Electronics',
      year: '4th Year', hostelBlock: 'Block B, Room 310',
      phone: '+91-98765-22222', bloodGroup: 'A+',
    ),
  };

  String? login(String rollNumber, String password) {
    final storedPass = _credentials[rollNumber.toUpperCase()];
    if (storedPass == null) return 'Roll number not found';
    if (storedPass != password) return 'Incorrect password';
    _currentStudent = _studentDb[rollNumber.toUpperCase()];
    notifyListeners();
    return null; // null = success
  }

  void logout() {
    _currentStudent = null;
    notifyListeners();
  }

  // ── SOS Requests ─────────────────────────────────────────────────────────
  final List<SOSRequest> _sosRequests = [
    // Seed data so Request Status screen is not empty on first launch
    SOSRequest(
      id: 'sos-seed-1',
      studentId: 's1',
      studentName: 'Arjun Kumar',
      rollNumber: '2023CS001',
      category: SOSCategory.medical,
      description: 'Severe headache and dizziness in lab',
      location: 'CS Lab 3, Block D',
      submittedAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      status: RequestStatus.resolved,
      timeline: [
        StatusUpdate(message: 'SOS alert submitted. Campus security notified.', time: DateTime.now().subtract(const Duration(days: 2, hours: 3)), status: RequestStatus.submitted),
        StatusUpdate(message: 'Security team dispatched to CS Lab 3.', time: DateTime.now().subtract(const Duration(days: 2, hours: 2, minutes: 50)), status: RequestStatus.inProgress),
        StatusUpdate(message: 'Student escorted to health center. Stable condition.', time: DateTime.now().subtract(const Duration(days: 2, hours: 2)), status: RequestStatus.resolved),
      ],
    ),
  ];

  List<SOSRequest> sosForCurrentStudent() =>
      _sosRequests.where((s) => s.studentId == _currentStudent?.id).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  SOSRequest submitSOS({
    required SOSCategory category,
    required String description,
    required String location,
    required bool isAnonymous,
    String? videoPath,
  }) {
    final req = SOSRequest(
      id: const Uuid().v4(),
      studentId: _currentStudent!.id,
      studentName: isAnonymous ? 'Anonymous' : _currentStudent!.name,
      rollNumber: isAnonymous ? '****' : _currentStudent!.rollNumber,
      category: category,
      description: description,
      location: location,
      submittedAt: DateTime.now(),
      hasVideo: videoPath != null,
      videoPath: videoPath,
      isAnonymous: isAnonymous,
    );
    _sosRequests.add(req);
    notifyListeners();
    return req;
  }

  // ── Complaints ────────────────────────────────────────────────────────────
  final List<Complaint> _complaints = [
    Complaint(
      id: 'comp-seed-1',
      studentId: 's1',
      studentName: 'Arjun Kumar',
      rollNumber: '2023CS001',
      category: ComplaintCategory.facilityIssue,
      subject: 'Broken AC in Hostel Room',
      description: 'The AC in Block C Room 204 has not been working for 2 weeks.',
      location: 'Block C, Room 204',
      submittedAt: DateTime.now().subtract(const Duration(days: 5)),
      status: RequestStatus.underReview,
      timeline: [
        StatusUpdate(message: 'Complaint filed successfully. Under review.', time: DateTime.now().subtract(const Duration(days: 5)), status: RequestStatus.submitted),
        StatusUpdate(message: 'Maintenance team notified. Inspection scheduled.', time: DateTime.now().subtract(const Duration(days: 3)), status: RequestStatus.underReview),
      ],
    ),
  ];

  List<Complaint> complaintsForCurrentStudent() =>
      _complaints.where((c) => c.studentId == _currentStudent?.id).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  Complaint submitComplaint({
    required ComplaintCategory category,
    required String subject,
    required String description,
    required String location,
    required bool isAnonymous,
    required List<String> mediaPaths,
    required List<String> mediaTypes,
    String? againstPerson,
  }) {
    final comp = Complaint(
      id: const Uuid().v4(),
      studentId: _currentStudent!.id,
      studentName: isAnonymous ? 'Anonymous' : _currentStudent!.name,
      rollNumber: isAnonymous ? '****' : _currentStudent!.rollNumber,
      category: category,
      subject: subject,
      description: description,
      location: location,
      submittedAt: DateTime.now(),
      mediaPaths: mediaPaths,
      mediaTypes: mediaTypes,
      isAnonymous: isAnonymous,
      againstPerson: againstPerson,
    );
    _complaints.add(comp);
    notifyListeners();
    return comp;
  }
}
