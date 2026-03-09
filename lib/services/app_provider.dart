import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AppProvider extends ChangeNotifier {
  static final AppProvider _i = AppProvider._();
  factory AppProvider() => _i;
  AppProvider._();

  AuthStatus _authStatus = AuthStatus.unknown;
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _dashboardData;

  AuthStatus get authStatus => _authStatus;
  Map<String, dynamic>? get currentUser => _currentUser;
  Map<String, dynamic>? get dashboardData => _dashboardData;
  bool get isAdmin => _currentUser?['role'] == 'admin';
  bool get isStudent => _currentUser?['role'] == 'student';

  // ── Boot ──────────────────────────────────────────────────────────────────
  Future<void> tryAutoLogin() async {
    final token = await ApiService().getToken();
    if (token == null) {
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _currentUser = await ApiService().getMe();
      _authStatus = AuthStatus.authenticated;
    } catch (_) {
      await ApiService().deleteToken();
      _authStatus = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> login(String roll, String password, String role) async {
    final data = await ApiService().login(roll, password, role);
    _currentUser = data['user'];
    _authStatus = AuthStatus.authenticated;
    notifyListeners();
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await ApiService().deleteToken();
    _currentUser = null;
    _dashboardData = null;
    _authStatus = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> loadDashboard() async {
    if (isAdmin) {
      _dashboardData = await ApiService().getAdminDashboard();
    } else {
      _dashboardData = await ApiService().getStudentDashboard();
    }
    notifyListeners();
    return _dashboardData!;
  }
}
