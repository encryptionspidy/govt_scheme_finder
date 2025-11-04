import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  late Map<String, String> _localizedStrings;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ta'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  Future<void> load() async {
    final String jsonString =
        await rootBundle.loadString('assets/translations/${locale.languageCode}.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    _localizedStrings = jsonMap.map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  String translate(String key) => _localizedStrings[key] ?? key;

  bool get isTamil => locale.languageCode == 'ta';

  String localizedValue(Map<String, dynamic> localizedMap) {
    final String languageCode = locale.languageCode;
    if (localizedMap.containsKey(languageCode)) {
      final dynamic value = localizedMap[languageCode];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return localizedMap['en']?.toString() ?? '';
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension LocalizationX on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
}
