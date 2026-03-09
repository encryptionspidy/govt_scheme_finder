import 'package:hive/hive.dart';

import '../local/hive_boxes.dart';
import '../models/scheme.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';

class SchemeRepository {
  SchemeRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Box get _cacheBox => Hive.box(HiveBoxes.schemesCache);

  Future<List<Scheme>> fetchRecommendations(
    UserProfile profile, {
    required bool networkAvailable,
  }) async {
    final String key =
        'recommendations_${profile.state}_${profile.gender}_${profile.occupation}_${profile.income}_${profile.age}';
    if (networkAvailable) {
      try {
        final List<Scheme> remote =
            await _apiService.fetchRecommendations(profile);
        await _saveSchemes(key, remote);
        return remote;
      } on ApiException {
        return _readSchemes(key);
      }
    }
    return _readSchemes(key);
  }

  Future<List<Scheme>> fetchByCategory(String category,
      {required bool networkAvailable}) async {
    final String key = 'category_$category';
    if (networkAvailable) {
      try {
        final List<Scheme> remote = await _apiService.fetchByCategory(category);
        await _saveSchemes(key, remote);
        return remote;
      } on ApiException {
        return _readSchemes(key);
      }
    }
    return _readSchemes(key);
  }

  Future<List<Scheme>> fetchByState(String state,
      {required bool networkAvailable}) async {
    final String key = 'state_$state';
    if (networkAvailable) {
      try {
        final List<Scheme> remote = await _apiService.fetchByState(state);
        await _saveSchemes(key, remote);
        return remote;
      } on ApiException {
        return _readSchemes(key);
      }
    }
    return _readSchemes(key);
  }

  Future<List<Scheme>> fetchAll(
      {bool forceRefresh = false, bool networkAvailable = true}) async {
    const String key = 'all';
    if (!forceRefresh) {
      final List<Scheme> cached = _readSchemes(key);
      if (cached.isNotEmpty) {
        return cached;
      }
    }
    if (networkAvailable) {
      try {
        final List<Scheme> remote = await _apiService.fetchAll();
        await _saveSchemes(key, remote);
        return remote;
      } on ApiException {
        return _readSchemes(key);
      }
    }
    return _readSchemes(key);
  }

  Future<List<Scheme>> fetchAllStaleWhileRevalidate({
    required bool networkAvailable,
  }) async {
    const String key = 'all';
    final List<Scheme> cached = _readSchemes(key);
    if (cached.isNotEmpty) {
      if (networkAvailable) {
        _apiService.fetchAll().then((List<Scheme> remote) {
          _saveSchemes(key, remote);
        }).catchError((_) {
          // keep stale cache when refresh fails
        });
      }
      return cached;
    }

    return fetchAll(forceRefresh: true, networkAvailable: networkAvailable);
  }

  Future<List<Scheme>> search(String query,
      {bool networkAvailable = true}) async {
    final List<Scheme> pool =
        await fetchAll(networkAvailable: networkAvailable);
    final String lower = query.toLowerCase();
    return pool.where((Scheme scheme) {
      final String title = (scheme.title['en']?.toString() ?? '').toLowerCase();
      final String description =
          (scheme.shortDescription['en']?.toString() ?? '').toLowerCase();
      return title.contains(lower) || description.contains(lower);
    }).toList();
  }

  Future<void> _saveSchemes(String key, List<Scheme> schemes) async {
    await _cacheBox.put(
      key,
      schemes.map((Scheme scheme) => scheme.toMap()).toList(),
    );
  }

  List<Scheme> _readSchemes(String key) {
    final List<dynamic>? cached = _cacheBox.get(key) as List?;
    if (cached == null) return <Scheme>[];
    return cached
        .map((dynamic item) =>
            Scheme.fromMap((item as Map).cast<String, dynamic>()))
        .toList();
  }

  void dispose() {
    _apiService.dispose();
  }
}
