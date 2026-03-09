import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  static const _tokenKey = 'auth_token';

  // ── Token management ──────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Core helpers ──────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _handleResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return Future.value(null);
      return Future.value(jsonDecode(res.body));
    }
    dynamic body;
    try { body = jsonDecode(res.body); } catch (_) { body = {}; }
    throw ApiException(body['detail'] ?? 'Request failed (${res.statusCode})');
  }

  // 10-second timeout for all requests — shows error instead of hanging forever
  static const _timeout = Duration(seconds: 10);

  Future<dynamic> get(String path) async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('$kBaseUrl$path'), headers: headers)
        .timeout(_timeout, onTimeout: () => throw ApiException(
            'Connection timed out. Check your server IP and ensure the backend is running.'));
    return _handleResponse(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final res = await http
        .post(Uri.parse('$kBaseUrl$path'), headers: headers, body: jsonEncode(body))
        .timeout(_timeout, onTimeout: () => throw ApiException(
            'Connection timed out. Check your server IP and ensure the backend is running.'));
    return _handleResponse(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final res = await http
        .patch(Uri.parse('$kBaseUrl$path'), headers: headers, body: jsonEncode(body))
        .timeout(_timeout, onTimeout: () => throw ApiException(
            'Connection timed out. Check your server IP and ensure the backend is running.'));
    return _handleResponse(res);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String rollNumber, String password, String role) async {
    final data = await post('/auth/login', {
      'roll_number': rollNumber,
      'password': password,
      'role': role,
    });
    await saveToken(data['access_token']);
    return data;
  }

  Future<Map<String, dynamic>> getMe() async => await get('/auth/me');

  // ── SOS ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> submitSOS(Map<String, dynamic> body) async =>
      await post('/sos/', body);

  Future<List<dynamic>> getMySOS() async => await get('/sos/my');

  Future<List<dynamic>> adminGetAllSOS({String? status, String? category}) async {
    String path = '/sos/admin/all';
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (category != null) params.add('category=$category');
    if (params.isNotEmpty) path += '?${params.join('&')}';
    return await get(path);
  }

  Future<Map<String, dynamic>> updateSOSStatus(
          String id, String status, String message) async =>
      await patch('/sos/admin/$id/status', {'status': status, 'message': message});

  // ── Complaints ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> submitComplaint(Map<String, dynamic> body) async =>
      await post('/complaints/', body);

  Future<List<dynamic>> getMyComplaints() async => await get('/complaints/my');

  Future<List<dynamic>> adminGetAllComplaints({String? status, String? category}) async {
    String path = '/complaints/admin/all';
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (category != null) params.add('category=$category');
    if (params.isNotEmpty) path += '?${params.join('&')}';
    return await get(path);
  }

  Future<Map<String, dynamic>> updateComplaintStatus(
          String id, String status, String message) async =>
      await patch('/complaints/admin/$id/status', {'status': status, 'message': message});

  // ── Dashboard ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStudentDashboard() async =>
      await get('/dashboard/student');

  Future<Map<String, dynamic>> getAdminDashboard() async =>
      await get('/dashboard/admin');

  // ── Admin ─────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getStudentList() async => await get('/admin/students');

  // ── File Upload → Cloudinary (via backend) ────────────────────────────────

  /// Upload SOS evidence video. Returns full response map including
  /// 'url', 'thumbnail_url', 'duration', 'public_id'.
  Future<Map<String, dynamic>> uploadSOSVideo(XFile file, String sosId) async {
    final token = await getToken();
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw ApiException('Selected video file is empty.');

    final filename = _safeFilename(file.name, 'sos_video.mp4');
    final contentType = _guessVideoContentType(filename);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$kBaseUrl/upload/sos-video'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'file', bytes,
      filename: filename,
      contentType: _mediaType(contentType),
    ));
    request.fields['sos_id'] = sosId;

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    dynamic errBody;
    try { errBody = jsonDecode(res.body); } catch (_) { errBody = {}; }
    throw ApiException(errBody['detail'] ?? 'Video upload failed (${res.statusCode})');
  }

  /// Upload complaint evidence (photo or video).
  /// Returns full response map including 'url', 'thumbnail_url', 'resource_type'.
  Future<Map<String, dynamic>> uploadComplaintMedia(
      XFile file, String complaintId, String mediaType) async {
    final token = await getToken();
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw ApiException('Selected file is empty.');

    final isVideo = mediaType.toLowerCase() == 'video';
    final fallbackName = isVideo ? 'complaint_video.mp4' : 'complaint_photo.jpg';
    final filename = _safeFilename(file.name, fallbackName);
    final contentType = isVideo
        ? _guessVideoContentType(filename)
        : _guessImageContentType(filename);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$kBaseUrl/upload/complaint-media'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'file', bytes,
      filename: filename,
      contentType: _mediaType(contentType),
    ));
    request.fields['complaint_id'] = complaintId;
    request.fields['media_type'] = mediaType.toLowerCase();

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    dynamic errBody;
    try { errBody = jsonDecode(res.body); } catch (_) { errBody = {}; }
    throw ApiException(errBody['detail'] ?? 'File upload failed (${res.statusCode})');
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  String _safeFilename(String name, String fallback) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _guessVideoContentType(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    const map = {
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'webm': 'video/webm',
      '3gp': 'video/3gpp',
    };
    return map[ext] ?? 'video/mp4';
  }

  String _guessImageContentType(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
    };
    return map[ext] ?? 'image/jpeg';
  }

  http.MediaType _mediaType(String ct) {
    final parts = ct.split('/');
    return http.MediaType(parts[0], parts.length > 1 ? parts[1] : '*');
  }

  // Keep old method names as aliases for backward compatibility
  Future<String> uploadSOSVideoWeb(XFile file, String sosId) async {
    final result = await uploadSOSVideo(file, sosId);
    return result['url'] as String;
  }

  Future<String> uploadComplaintMediaWeb(
      XFile file, String complaintId, String mediaType) async {
    final result = await uploadComplaintMedia(file, complaintId, mediaType);
    return result['url'] as String;
  }

  // ── CCTV Monitoring ───────────────────────────────────────────────────────

  Future<List<dynamic>> getCCTVAlerts({String? status, String? incidentType}) async {
    String path = '/cctv/alerts';
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (incidentType != null) params.add('incident_type=$incidentType');
    if (params.isNotEmpty) path += '?${params.join('&')}';
    return await get(path);
  }

  Future<List<dynamic>> getPendingCCTVAlerts() async =>
      await get('/cctv/alerts/pending');

  Future<Map<String, dynamic>> getCCTVAlertDetails(String alertId) async =>
      await get('/cctv/alerts/$alertId');

  Future<void> acknowledgeCCTVAlert(String alertId) async =>
      await patch('/cctv/alerts/$alertId/acknowledge', {});

  Future<Map<String, dynamic>> updateCCTVAlertStatus(
      String alertId, String status, String message) async =>
      await patch('/cctv/alerts/$alertId/status', {
        'status': status,
        'message': message,
      });

  Future<Map<String, dynamic>> simulateCCTVAlert(Map<String, dynamic> data) async =>
      await post('/cctv/simulate-alert', data);

  Future<Map<String, dynamic>> uploadCCTVVideo(String alertId, String filePath) async {
    final token = await getToken();
    final file = XFile(filePath);
    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) throw ApiException('Selected video file is empty.');

    final filename = _safeFilename(file.name, 'cctv_video.mp4');
    final contentType = _guessVideoContentType(filename);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$kBaseUrl/cctv/upload-alert-video/$alertId'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'video', bytes,
      filename: filename,
      contentType: _mediaType(contentType),
    ));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    dynamic errBody;
    try { errBody = jsonDecode(res.body); } catch (_) { errBody = {}; }
    throw ApiException(errBody['detail'] ?? 'Video upload failed (${res.statusCode})');
  }

  Future<Map<String, dynamic>> getCameraList() async =>
      await get('/cctv/cameras/list');

  /// Send video to backend YOLO analyzer. Returns detection result.
  Future<Map<String, dynamic>> analyzeCCTVVideo(XFile file) async {
    final token = await getToken();
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw ApiException('Selected video file is empty.');

    final filename = _safeFilename(file.name, 'cctv_analysis.mp4');
    final contentType = _guessVideoContentType(filename);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$kBaseUrl/cctv/analyze-video'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'video', bytes,
      filename: filename,
      contentType: _mediaType(contentType),
    ));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    dynamic errBody;
    try { errBody = jsonDecode(res.body); } catch (_) { errBody = {}; }
    throw ApiException(errBody['detail'] ?? 'Analysis failed (${res.statusCode})');
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
