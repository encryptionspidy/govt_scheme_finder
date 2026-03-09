import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../utils/constants.dart';
import '../models/scheme.dart';
import '../models/user_profile.dart';
import '../models/notification_item.dart';

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrls = _resolveBaseUrls(baseUrl: baseUrl);

  final http.Client _client;
  final List<String> _baseUrls;

  static const Duration _requestTimeout = Duration(seconds: 8);

  Uri _buildUri(String baseUrl, String path, [Map<String, String>? query]) {
    final Uri base = Uri.parse(baseUrl);
    final List<String> baseSegments =
        base.pathSegments.where((String s) => s.isNotEmpty).toList();
    final List<String> extraSegments =
        path.split('/').where((String segment) => segment.isNotEmpty).toList();

    return base.replace(
      pathSegments: <String>[...baseSegments, ...extraSegments],
      queryParameters: query,
    );
  }

  Future<http.Response> _request(
    String path, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? query,
  }) async {
    Exception? lastError;

    for (final String baseUrl in _baseUrls) {
      final Uri uri = _buildUri(baseUrl, path, query);
      try {
        debugPrint('[ApiService] $method $uri');
        final Future<http.Response> call = method == 'POST'
            ? _client.post(uri, headers: headers, body: body)
            : _client.get(uri, headers: headers);
        final http.Response response = await call.timeout(_requestTimeout);
        if (response.statusCode >= 500 && _baseUrls.length > 1) {
          debugPrint(
            '[ApiService] Server error ${response.statusCode} on $uri; trying next base URL if available',
          );
          continue;
        }
        return response;
      } on TimeoutException catch (error) {
        lastError = ApiException('Request timeout for $uri');
        debugPrint('[ApiService] Timeout for $uri: $error');
      } on Exception catch (error) {
        lastError = error;
        debugPrint('[ApiService] Request failed for $uri: $error');
      }
    }

    throw ApiException(
      'Unable to connect to backend. Tried: ${_baseUrls.join(', ')}. '
      'Last error: ${lastError ?? 'unknown'}',
    );
  }

  Future<List<Scheme>> fetchRecommendations(UserProfile profile) async {
    final http.Response response = await _request(
      '/schemes/recommendations',
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profile.toMap()),
    );
    return _parseSchemesResponse(response, key: 'data');
  }

  Future<List<Scheme>> fetchByCategory(String category) async {
    final http.Response response =
        await _request('/schemes/category/$category');
    return _parseSchemesResponse(response);
  }

  Future<List<Scheme>> fetchByState(String state) async {
    final http.Response response = await _request('/schemes/state/$state');
    return _parseSchemesResponse(response);
  }

  Future<List<Scheme>> fetchAll() async {
    final http.Response response = await _request('/schemes');
    return _parseSchemesResponse(response);
  }

  Future<List<AppNotification>> fetchNotifications() async {
    final http.Response response = await _request('/notifications');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> body = _decodeObject(response.body);
      final List<dynamic> list =
          (body['data'] as List?) ?? (body['notifications'] as List?) ?? [];
      return list
          .map((dynamic item) =>
              AppNotification.fromMap((item as Map).cast<String, dynamic>()))
          .toList();
    }
    throw ApiException('Failed to load notifications (${response.statusCode})');
  }

  List<Scheme> _parseSchemesResponse(http.Response response,
      {String key = 'data'}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> body = _decodeObject(response.body);
      final List<dynamic> list =
          (body[key] as List?) ?? (body['schemes'] as List?) ?? [];
      try {
        return list
            .map((dynamic item) =>
                Scheme.fromMap((item as Map).cast<String, dynamic>()))
            .toList();
      } catch (error) {
        debugPrint('[ApiService] Scheme parsing failed for key "$key": $error');
        throw ApiException('Failed to parse schemes payload: $error');
      }
    }
    debugPrint(
      '[ApiService] Failed to load schemes. status=${response.statusCode} body=${response.body}',
    );
    throw ApiException('Failed to load schemes (${response.statusCode})');
  }

  Map<String, dynamic> _decodeObject(String source) {
    final dynamic decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException('Unexpected JSON response shape');
  }

  void dispose() {
    _client.close();
  }

  static String _normalizeBaseUrl(String url) {
    final String trimmed =
        url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    if (trimmed.endsWith('/api/v1')) {
      return trimmed;
    }
    if (trimmed.endsWith('/api')) {
      return '$trimmed/v1';
    }
    return '$trimmed/api/v1';
  }

  static List<String> _resolveBaseUrls({String? baseUrl}) {
    final List<String> candidates = <String>[];

    void addCandidate(String value) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty) return;
      final String normalized = _normalizeBaseUrl(trimmed);
      if (!candidates.contains(normalized)) {
        candidates.add(normalized);
      }
    }

    addCandidate(baseUrl ?? '');
    addCandidate(defaultApiBaseUrl);

    if (kIsWeb) {
      addCandidate('${Uri.base.scheme}://${Uri.base.host}:4000');
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          addCandidate('http://10.0.2.2:4000');
          addCandidate('http://localhost:4000');
          break;
        case TargetPlatform.iOS:
          addCandidate('http://localhost:4000');
          break;
        default:
          addCandidate('http://localhost:4000');
          addCandidate('http://127.0.0.1:4000');
          break;
      }
    }

    return candidates;
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => 'ApiException: $message';
}
