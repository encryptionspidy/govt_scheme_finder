import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/constants.dart';
import '../models/scheme.dart';
import '../models/user_profile.dart';
import '../models/notification_item.dart';

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(baseUrl ?? defaultApiBaseUrl);

  final http.Client _client;
  final String _baseUrl;

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final Uri base = Uri.parse(_baseUrl);
    final List<String> baseSegments = base.pathSegments.where((String s) => s.isNotEmpty).toList();
    final List<String> extraSegments = path
        .split('/')
        .where((String segment) => segment.isNotEmpty)
        .toList();

    return base.replace(
      pathSegments: <String>[...baseSegments, ...extraSegments],
      queryParameters: query,
    );
  }

  Future<List<Scheme>> fetchRecommendations(UserProfile profile) async {
    final Uri uri = _buildUri('/schemes/recommendations');
    final http.Response response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profile.toMap()),
    );
    return _parseSchemesResponse(response, key: 'recommendations');
  }

  Future<List<Scheme>> fetchByCategory(String category) async {
    final Uri uri = _buildUri('/schemes/category/$category');
    final http.Response response = await _client.get(uri);
    return _parseSchemesResponse(response);
  }

  Future<List<Scheme>> fetchByState(String state) async {
    final Uri uri = _buildUri('/schemes/state/$state');
    final http.Response response = await _client.get(uri);
    return _parseSchemesResponse(response);
  }

  Future<List<Scheme>> fetchAll() async {
    final Uri uri = _buildUri('/schemes');
    final http.Response response = await _client.get(uri);
    return _parseSchemesResponse(response);
  }

  Future<List<AppNotification>> fetchNotifications() async {
    final Uri uri = _buildUri('/notifications');
    final http.Response response = await _client.get(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = (body['notifications'] as List?) ?? [];
      return list
          .map((dynamic item) =>
              AppNotification.fromMap((item as Map).cast<String, dynamic>()))
          .toList();
    }
    throw ApiException('Failed to load notifications (${response.statusCode})');
  }

  List<Scheme> _parseSchemesResponse(http.Response response, {String key = 'schemes'}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = (body[key] as List?) ?? [];
      return list
          .map((dynamic item) =>
              Scheme.fromMap((item as Map).cast<String, dynamic>()))
          .toList();
    }
    throw ApiException('Failed to load schemes (${response.statusCode})');
  }

  void dispose() {
    _client.close();
  }

  static String _normalizeBaseUrl(String url) {
    final String trimmed = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    if (trimmed.endsWith('/api')) {
      return trimmed;
    }
    return '$trimmed/api';
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => 'ApiException: $message';
}
