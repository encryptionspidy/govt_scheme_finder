import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../data/local/hive_boxes.dart';
import '../data/models/scheme.dart';
import '../utils/constants.dart';
import 'app_language_provider.dart';
import 'schemes_provider.dart';

class BookmarksProvider extends ChangeNotifier {
  BookmarksProvider();

  final List<Scheme> _bookmarks = <Scheme>[];
  bool _initialized = false;
  late SchemesProvider _schemesProvider;
  late AppLanguageProvider _languageProvider;

  List<Scheme> get bookmarks => List.unmodifiable(_bookmarks);

  void attachDependencies(
    SchemesProvider schemesProvider,
    AppLanguageProvider languageProvider,
  ) {
    _schemesProvider = schemesProvider;
    _languageProvider = languageProvider;
    if (!_initialized) {
      _loadFromHive();
      _initialized = true;
    }
  }

  Future<void> _loadFromHive() async {
    final Box box = Hive.box(HiveBoxes.bookmarks);
    final List<dynamic> stored = box.values.toList();
    _bookmarks
      ..clear()
      ..addAll(stored.map((dynamic item) => Scheme.fromMap((item as Map).cast<String, dynamic>())));
    notifyListeners();
  }

  bool isBookmarked(String schemeId) => _bookmarks.any((Scheme scheme) => scheme.id == schemeId);

  Future<void> toggleBookmark(Scheme scheme) async {
    final Box box = Hive.box(HiveBoxes.bookmarks);
    if (isBookmarked(scheme.id)) {
      _bookmarks.removeWhere((Scheme item) => item.id == scheme.id);
      await box.delete(scheme.id);
    } else {
      _bookmarks.add(scheme);
      await box.put(scheme.id, scheme.toMap());
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    final Box box = Hive.box(HiveBoxes.bookmarks);
    await box.clear();
    _bookmarks.clear();
    notifyListeners();
  }

  String quickApplyUrl(Scheme scheme) {
    final String id = scheme.id;
    if (schemeQuickApplyLinks.containsKey(id)) {
      return schemeQuickApplyLinks[id]!;
    }
    final String? url = scheme.applicationUrl;
    return url?.isNotEmpty ?? false
        ? url!
        : 'https://www.myscheme.gov.in/scheme/${scheme.id}';
  }

  String localizedTitle(Scheme scheme) {
    return _languageProvider.locale.languageCode == 'ta'
        ? (scheme.title['ta']?.toString().isNotEmpty ?? false
            ? scheme.title['ta']!.toString()
            : scheme.title['en']?.toString() ?? '')
        : scheme.title['en']?.toString() ?? '';
  }

  Future<void> restoreFromCache() async {
    final List<Scheme> cached = await _schemesProvider.cachedAllSchemes();
    // Ensure bookmarked schemes reference latest data if available.
    for (int i = 0; i < _bookmarks.length; i++) {
      final Scheme bookmark = _bookmarks[i];
      final Scheme updated = cached.firstWhere(
        (Scheme scheme) => scheme.id == bookmark.id,
        orElse: () => bookmark,
      );
      _bookmarks[i] = updated;
    }
    notifyListeners();
  }
}
