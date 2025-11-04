import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/app_language_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

class SchemePlusApp extends StatelessWidget {
  const SchemePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLanguageProvider>(
      builder: (BuildContext context, AppLanguageProvider languageProvider, _) {
        return MaterialApp(
          title: 'SchemePlus',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: languageProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
