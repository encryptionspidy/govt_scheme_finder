import 'package:flutter/material.dart';

import '../data/models/scheme.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/scheme_repository.dart';
import '../utils/constants.dart';
import 'connectivity_provider.dart';
import 'user_profile_provider.dart';

class SchemesProvider extends ChangeNotifier {
  SchemesProvider() : _repository = SchemeRepository();

  final SchemeRepository _repository;
  UserProfileProvider? _profileProvider;
  ConnectivityProvider? _connectivityProvider;

  List<Scheme> _recommendations = <Scheme>[];
  List<Scheme> _categorySchemes = <Scheme>[];
  List<Scheme> _stateSchemes = <Scheme>[];
  List<Scheme> _searchResults = <Scheme>[];
  List<Scheme> _allSchemes = <Scheme>[];
  bool _isLoading = false;
  String? _error;
  bool _allSchemesLoaded = false;
  Map<String, int> _categoryCounts = <String, int>{};
  String _selectedCategory = categories.first;
  String _selectedState = indianStates.first;

  List<Scheme> get recommendations => _recommendations;
  List<Scheme> get categorySchemes => _categorySchemes;
  List<Scheme> get stateSchemes => _stateSchemes;
  List<Scheme> get searchResults => _searchResults;
  List<Scheme> get allSchemes => _allSchemes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => !(_connectivityProvider?.isOnline ?? true);
  Map<String, int> get categoryCounts => _categoryCounts;
  String get selectedCategory => _selectedCategory;
  String get selectedState => _selectedState;

  Scheme? get heroScheme {
    if (_recommendations.isNotEmpty) {
      return _recommendations.first;
    }
    if (_allSchemes.isNotEmpty) {
      return _allSchemes.first;
    }
    return null;
  }

  List<Scheme> get topFeaturedSchemes {
    if (_recommendations.length >= 6) {
      return _recommendations.take(6).toList();
    }
    if (_allSchemes.length >= 6) {
      return _allSchemes.take(6).toList();
    }
    return _recommendations.isNotEmpty ? _recommendations : _allSchemes;
  }

  void attachDependencies(
    UserProfileProvider profileProvider,
    ConnectivityProvider connectivityProvider,
  ) {
    if (_profileProvider != profileProvider) {
      _profileProvider?.removeListener(_onProfileChanged);
      _profileProvider = profileProvider
        ..addListener(_onProfileChanged);
    }
    _connectivityProvider = connectivityProvider;
    // Preload all schemes on initialization
    if (!_allSchemesLoaded) {
      fetchAllCategories();
    }
  }

  Future<void> _onProfileChanged() async {
    if (_profileProvider?.isProfileComplete ?? false) {
      await loadRecommendations();
    }
  }

  Future<void> loadRecommendations() async {
    final UserProfile? profile = _profileProvider?.profile;
    if (profile == null) return;
    await _load(
      () => _repository.fetchRecommendations(
        profile,
        networkAvailable: _connectivityProvider?.isOnline ?? true,
      ),
      assign: (List<Scheme> data) {
        _recommendations = data;
        if (data.isNotEmpty) {
          _cacheAllSchemes(data);
        }
      },
    );
  }

  Future<void> loadByCategory(String category) async {
    _selectedCategory = category;
    await _load(
      () => _repository.fetchByCategory(
        category,
        networkAvailable: _connectivityProvider?.isOnline ?? true,
      ),
      assign: (List<Scheme> data) => _categorySchemes = data,
    );
  }

  Future<void> loadByState(String state) async {
    _selectedState = state;
    await _load(
      () => _repository.fetchByState(
        state,
        networkAvailable: _connectivityProvider?.isOnline ?? true,
      ),
      assign: (List<Scheme> data) => _stateSchemes = data,
    );
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = <Scheme>[];
      notifyListeners();
      return;
    }
    await _load(
      () => _repository.search(
        query,
        networkAvailable: _connectivityProvider?.isOnline ?? true,
      ),
      assign: (List<Scheme> data) => _searchResults = data,
      silent: true,
    );
  }

  Future<List<Scheme>> cachedAllSchemes() async {
    return _repository.fetchAll(networkAvailable: false);
  }

  Future<void> fetchAllCategories({bool forceRefresh = false}) async {
    if (_allSchemesLoaded && !forceRefresh) return;
    try {
      final List<Scheme> all = await _repository.fetchAll(
        forceRefresh: forceRefresh,
        networkAvailable: _connectivityProvider?.isOnline ?? true,
      );
      _cacheAllSchemes(all);
      _allSchemesLoaded = true;
      notifyListeners();
    } catch (e) {
      try {
        final List<Scheme> cached = await _repository.fetchAll(
          forceRefresh: false,
          networkAvailable: false,
        );
        if (cached.isNotEmpty) {
          _cacheAllSchemes(cached);
          _allSchemesLoaded = true;
          notifyListeners();
        }
      } catch (_) {
        // swallow
      }
    }
  }

  void _cacheAllSchemes(List<Scheme> schemes) {
    _allSchemes = schemes;
    _categoryCounts = <String, int>{};
    for (final Scheme scheme in schemes) {
      final String key = scheme.category;
      _categoryCounts[key] = (_categoryCounts[key] ?? 0) + 1;
    }
  }

  Future<void> _load(
    Future<List<Scheme>> Function() loader, {
    required void Function(List<Scheme>) assign,
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final List<Scheme> data = await loader();
      assign(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _profileProvider?.removeListener(_onProfileChanged);
    _repository.dispose();
    super.dispose();
  }
}
