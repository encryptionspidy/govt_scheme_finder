import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../data/local/hive_boxes.dart';
import '../l10n/app_localizations.dart';

class AppLanguageProvider extends ChangeNotifier {
  AppLanguageProvider() {
    _restore();
  }

  Locale _locale = AppLocalizations.supportedLocales.first;

  Locale get locale => _locale;

  Future<void> _restore() async {
    final Box box = Hive.box(HiveBoxes.profile);
    final String? saved = box.get('languageCode') as String?;
    if (saved != null) {
      _locale = AppLocalizations.supportedLocales.firstWhere(
        (locale) => locale.languageCode == saved,
        orElse: () => AppLocalizations.supportedLocales.first,
      );
      notifyListeners();
    }
  }

  Future<void> changeLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final Box box = Hive.box(HiveBoxes.profile);
    await box.put('languageCode', locale.languageCode);
    notifyListeners();
  }
}
