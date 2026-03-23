import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'auth_storage.dart';

class ApiService {
  static const String baseUrl =
      'https://japanese-listening-learning-app-be.onrender.com/api/v1'; // 10.0.2.2 for Android Emulator

  static Map<String, String> _headers({bool withAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    final token = AuthStorage.token;
    if (withAuth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _parseResponse(http.Response response) async {
    final body = json.decode(response.body);
    if (body is! Map<String, dynamic>) throw Exception('Invalid response');
    if (response.statusCode >= 400) {
      final msg = body['message'] ?? 'Request failed ${response.statusCode}';
      throw Exception(msg);
    }
    return body;
  }

  // ─── Auth ───────────────────────────────────────────────────

  /// POST /auth/login → { success, data: { accessToken, profiles, ... } }
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(withAuth: false),
      body: json.encode({'username': username, 'password': password}),
    );
    final body = await _parseResponse(res);
    if (body['success'] != true) throw Exception(body['message'] ?? 'Login failed');
    return body['data'] as Map<String, dynamic>;
  }

  /// POST /auth/register
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(withAuth: false),
      body: json.encode({
        'username': username,
        'password': password,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );
    final body = await _parseResponse(res);
    if (body['success'] != true) throw Exception(body['message'] ?? 'Register failed');
    return body['data'] as Map<String, dynamic>;
  }

  // ─── Profiles ────────────────────────────────────────────────

  /// GET /learners/me/profiles
  static Future<List<Map<String, dynamic>>> getMyProfiles() async {
    final res = await http.get(
      Uri.parse('$baseUrl/learners/me/profiles'),
      headers: _headers(),
    );
    final body = await _parseResponse(res);
    final data = body['data'];
    if (data is List) return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [];
  }

  /// POST /learners/me/profiles body: { levelId, name? }
  static Future<Map<String, dynamic>> createProfile(int levelId, {String? name}) async {
    final payload = <String, dynamic>{'levelId': levelId};
    if (name != null && name.trim().isNotEmpty) {
      payload['name'] = name.trim();
    }
    final res = await http.post(
      Uri.parse('$baseUrl/learners/me/profiles'),
      headers: _headers(),
      body: json.encode(payload),
    );
    final body = await _parseResponse(res);
    return body['data'] as Map<String, dynamic>;
  }

  /// GET /learners/me/profiles/{profileId}/progress
  static Future<Map<String, dynamic>> getProfileProgress(int profileId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/learners/me/profiles/$profileId/progress'),
      headers: _headers(),
    );
    final body = await _parseResponse(res);
    return body['data'] as Map<String, dynamic>;
  }

  // ─── Account ─────────────────────────────────────────────────

  /// GET /learners/me
  static Future<Map<String, dynamic>> getMyAccount() async {
    final res = await http.get(
      Uri.parse('$baseUrl/learners/me'),
      headers: _headers(),
    );
    final body = await _parseResponse(res);
    return body['data'] as Map<String, dynamic>;
  }

  /// POST /learners/me/avatar (multipart) → { avatarUrl }
  static Future<String> uploadLearnerAvatar(File file) async {
    final token = AuthStorage.token;
    final uri = Uri.parse('$baseUrl/learners/me/avatar');
    final req = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final body = await _parseResponse(res);
    final data = body['data'] as Map<String, dynamic>;
    return (data['avatarUrl'] ?? '').toString();
  }

  /// DELETE /learners/me/avatar
  static Future<void> deleteLearnerAvatar() async {
    final res = await http.delete(
      Uri.parse('$baseUrl/learners/me/avatar'),
      headers: _headers(),
    );
    await _parseResponse(res);
  }

  /// POST /learners/me/profiles/{profileId}/avatar (multipart) → { avatarUrl }
  static Future<String> uploadProfileAvatar(int profileId, File file) async {
    final token = AuthStorage.token;
    final uri = Uri.parse('$baseUrl/learners/me/profiles/$profileId/avatar');
    final req = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final body = await _parseResponse(res);
    final data = body['data'] as Map<String, dynamic>;
    return (data['avatarUrl'] ?? '').toString();
  }

  /// PATCH /learners/me/profiles/{profileId} body: { avatarUrl?, name? }
  static Future<Map<String, dynamic>> updateProfile(
    int profileId, {
    String? avatarUrl,
    String? name,
  }) async {
    final payload = <String, dynamic>{};
    if (avatarUrl != null) payload['avatarUrl'] = avatarUrl;
    if (name != null) payload['name'] = name;
    final res = await http.patch(
      Uri.parse('$baseUrl/learners/me/profiles/$profileId'),
      headers: _headers(),
      body: json.encode(payload),
    );
    final body = await _parseResponse(res);
    return body['data'] as Map<String, dynamic>;
  }

  // ─── Levels & Topics ─────────────────────────────────────────

  /// GET /levels
  static Future<List<Map<String, dynamic>>> getLevels() async {
    final res = await http.get(
      Uri.parse('$baseUrl/levels'),
      headers: _headers(),
    );
    final body = await _parseResponse(res);
    final data = body['data'];
    if (data is List) return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [];
  }

  static Future<List<Map<String, dynamic>>> getTopicsByLevel(
    int levelId, {
    int? profileId,
  }) async {
    final uri = Uri.parse('$baseUrl/levels/$levelId/topics').replace(
      queryParameters: profileId != null ? {'profileId': profileId.toString()} : null,
    );
    final res = await http.get(uri, headers: _headers());
    final body = await _parseResponse(res);
    final data = body['data'];
    if (data is List) return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [];
  }

  // ─── Tests by topic ──────────────────────────────────────────

  /// GET /topics/{topicId}/tests → paginated, content = list of TestSummary
  static Future<List<Map<String, dynamic>>> getTestsByTopic(int topicId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/topics/$topicId/tests?page=0&size=50'),
      headers: _headers(),
    );
    final body = await _parseResponse(res);
    final data = body['data'];
    if (data is! Map) return [];
    final content = data['content'];
    if (content is List) return content.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [];
  }

  // ─── Vocabularies by topic ───────────────────────────────────

  static Future<List<Map<String, dynamic>>> getVocabulariesByTopic(int topicId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/topics/$topicId/vocabularies'),
      headers: _headers(),
    );
    final body = await _parseResponse(res);
    final data = body['data'];
    if (data is List) return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [];
  }

  // ─── Test flow ───────────────────────────────────────────────

  /// POST /tests/{testId}/start body: { profileId }
  static Future<Map<String, dynamic>> startTest(int testId, int profileId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tests/$testId/start'),
      headers: _headers(),
      body: json.encode({'profileId': profileId}),
    );
    final body = await _parseResponse(res);
    return body['data'] as Map<String, dynamic>;
  }

  /// GET /tests/{testId}/questions?attemptId={resultId}
  static Future<List<Map<String, dynamic>>> getTestQuestions(int testId, int attemptId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/tests/$testId/questions?attemptId=$attemptId'),
      headers: _headers(),
    );
    final body = await _parseResponse(res);
    final data = body['data'];
    if (data is List) return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [];
  }

  /// GET /test-results/{resultId}?profileId=
  static Future<Map<String, dynamic>> getTestResultDetail(int resultId, int profileId) async {
    final uri = Uri.parse('$baseUrl/test-results/$resultId').replace(
      queryParameters: {'profileId': profileId.toString()},
    );
    final res = await http.get(uri, headers: _headers());
    final body = await _parseResponse(res);
    return body['data'] as Map<String, dynamic>;
  }

  /// GET /profiles/{profileId}/test-results?page=&size=
  static Future<Map<String, dynamic>> getTestHistory(
    int profileId, {
    int page = 0,
    int size = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/profiles/$profileId/test-results')
        .replace(queryParameters: {'page': page.toString(), 'size': size.toString()});
    final res = await http.get(uri, headers: _headers());
    final body = await _parseResponse(res);
    return body['data'] as Map<String, dynamic>;
  }

  /// POST /test-results/{resultId}/submit body: { profileId, answers: [...] }
  static Future<Map<String, dynamic>> submitTest(
    int resultId,
    int profileId,
    List<Map<String, dynamic>> answers,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/test-results/$resultId/submit'),
      headers: _headers(),
      body: json.encode({'profileId': profileId, 'answers': answers}),
    );
    final body = await _parseResponse(res);
    return body['data'] as Map<String, dynamic>;
  }
}

// ─── Models ────────────────────────────────────────────────────

class TopicModel {
  final int id;
  final String title;
  final String subtitle;
  final double progress;
  final bool isUnlocked;
  final String emoji;
  final int order;

  TopicModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.isUnlocked,
    required this.emoji,
    required this.order,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    String getEmoji(String name) {
      if (name.contains('Chào hỏi')) return '⛩';
      if (name.contains('Số đếm')) return '🔢';
      if (name.contains('Gia đình')) return '👨‍👩‍👧';
      if (name.contains('Ẩm thực')) return '🍜';
      if (name.contains('Thời tiết')) return '🌿';
      return '📚';
    }
    return TopicModel(
      id: json['id'],
      title: json['topicName'] ?? '',
      subtitle: 'Bắt đầu học ngay',
      progress: 0.0,
      isUnlocked: json['isUnlocked'] ?? false,
      emoji: getEmoji(json['topicName']?.toString() ?? ''),
      order: json['topicOrder'] ?? 0,
    );
  }
}
