import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/assignment.dart';
import '../models/course.dart';
import '../models/dashboard_summary.dart';
import '../models/study_stats.dart';
import '../models/user.dart';

class ApiService {
  static const _tokenKey = 'auth_token';
  static final _client = http.Client();
  static const _timeout = Duration(seconds: 30);
  static const _longTimeout = Duration(seconds: 90);

  // ── Token storage ──

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Headers ──

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Map<String, String> _jsonHeaders() {
    return {'Content-Type': 'application/json'};
  }

  // ── Auth ──

  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/auth/register'),
      headers: _jsonHeaders(),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    ).timeout(_timeout);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      throw ApiException(body['error'] as String? ?? 'Registration failed');
    }
    await setToken(body['token'] as String);
    return body;
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(_timeout);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(body['error'] as String? ?? 'Login failed');
    }
    await setToken(body['token'] as String);
    return body;
  }

  /// Fire-and-forget ping to wake the server from Render's free-tier sleep.
  static void warmUp() {
    _client.get(Uri.parse('$apiBaseUrl/health')).ignore();
  }

  static Future<void> logout() async {
    await clearToken();
  }

  static Future<void> changePassword(
      String email, String currentPassword, String newPassword) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/auth/change-password'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': email,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    ).timeout(_timeout);
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw ApiException(body['error'] as String? ?? 'Failed to change password');
    }
  }

  // ── User ──

  static Future<User> getProfile() async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/user/profile'),
      headers: await _authHeaders(),
    ).timeout(_timeout);
    if (res.statusCode != 200) throw ApiException('Failed to load profile');
    return User.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> updateSettings({
    bool? notifications,
    int? notificationLeadTime,
    bool? darkMode,
  }) async {
    final body = <String, dynamic>{};
    if (notifications != null) body['notificationsEnabled'] = notifications;
    if (notificationLeadTime != null) body['notificationLeadTime'] = notificationLeadTime;
    if (darkMode != null) body['darkModeEnabled'] = darkMode;

    final res = await _client.put(
      Uri.parse('$apiBaseUrl/user/settings'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    if (res.statusCode != 200) throw ApiException('Failed to update settings');
  }

  // ── Assignments ──

  static Future<List<Assignment>> getAssignments() async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/assignments'),
      headers: await _authHeaders(),
    ).timeout(_timeout);
    if (res.statusCode != 200) {
      throw ApiException('Failed to load assignments');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((j) => Assignment.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<Assignment> updateAssignment(int id, {int? difficulty}) async {
    final body = <String, dynamic>{};
    if (difficulty != null) body['difficulty'] = difficulty;

    final res = await _client.put(
      Uri.parse('$apiBaseUrl/assignments/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    ).timeout(_timeout);
    if (res.statusCode != 200) {
      throw ApiException('Failed to update assignment');
    }
    return Assignment.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Dashboard ──

  static Future<DashboardSummary> getDashboardSummary() async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/dashboard/summary'),
      headers: await _authHeaders(),
    ).timeout(_timeout);
    if (res.statusCode != 200) throw ApiException('Failed to load dashboard');
    return DashboardSummary.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Insights ──

  static Future<String?> getStudyAdvice() async {
    try {
      final res = await _client.get(
        Uri.parse('$apiBaseUrl/insights/study-advice'),
        headers: await _authHeaders(),
      ).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['advice'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Calendar ──

  static Future<Map<String, List<Map<String, dynamic>>>> getCalendarMonth(
      int year, int month) async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/calendar/$year/$month'),
      headers: await _authHeaders(),
    ).timeout(_timeout);
    if (res.statusCode != 200) throw ApiException('Failed to load calendar');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data.map((key, value) {
      final assignments = (value as List<dynamic>)
          .map((a) => a as Map<String, dynamic>)
          .toList();
      return MapEntry(key, assignments);
    });
  }

  // ── Modules ──

  static Future<List<Course>> getModules() async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/modules'),
      headers: await _authHeaders(),
    ).timeout(_timeout);
    if (res.statusCode != 200) throw ApiException('Failed to load modules');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((j) => Course.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Study sessions ──

  static Future<void> logStudySession(int courseId, int durationMinutes) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/study-sessions'),
      headers: await _authHeaders(),
      body: jsonEncode({'courseId': courseId, 'duration': durationMinutes}),
    ).timeout(_timeout);
    if (res.statusCode != 201) {
      throw ApiException('Failed to log study session');
    }
  }

  static Future<StudyStats> getWeeklyStats() async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/study-sessions/weekly'),
      headers: await _authHeaders(),
    ).timeout(_timeout);
    if (res.statusCode != 200) throw ApiException('Failed to load stats');
    return StudyStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Moodle ICS sync ──

  static Future<Map<String, dynamic>> syncMoodle(String icsUrl) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/moodle/sync'),
      headers: await _authHeaders(),
      body: jsonEncode({'icsUrl': icsUrl}),
    ).timeout(_longTimeout);
    if (res.statusCode != 200) throw ApiException('Moodle sync failed');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMoodleStatus() async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/moodle/status'),
      headers: await _authHeaders(),
    ).timeout(_timeout);
    if (res.statusCode != 200) throw ApiException('Failed to load Moodle status');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> resyncMoodle() async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/moodle/resync'),
      headers: await _authHeaders(),
    ).timeout(_longTimeout);
    if (res.statusCode != 200) throw ApiException('Moodle re-sync failed');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> disconnectMoodle() async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/moodle/disconnect'),
      headers: await _authHeaders(),
    ).timeout(_timeout);
    if (res.statusCode != 200) throw ApiException('Failed to disconnect Moodle');
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
