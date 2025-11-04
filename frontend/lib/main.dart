import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/local/hive_boxes.dart';
import 'providers/app_language_provider.dart';
import 'providers/bookmarks_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/schemes_provider.dart';
import 'providers/user_profile_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox(HiveBoxes.bookmarks),
    Hive.openBox(HiveBoxes.schemesCache),
    Hive.openBox(HiveBoxes.profile),
    Hive.openBox(HiveBoxes.notifications),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppLanguageProvider()),
  ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProxyProvider2<UserProfileProvider, ConnectivityProvider, SchemesProvider>(
          create: (_) => SchemesProvider(),
          update: (_, profile, connectivity, provider) =>
              provider!..attachDependencies(profile, connectivity),
        ),
        ChangeNotifierProxyProvider2<SchemesProvider, AppLanguageProvider, BookmarksProvider>(
          create: (_) => BookmarksProvider(),
          update: (_, schemesProvider, languageProvider, bookmarksProvider) => bookmarksProvider!
            ..attachDependencies(schemesProvider, languageProvider),
        ),
        ChangeNotifierProxyProvider<ConnectivityProvider, NotificationsProvider>(
          create: (_) => NotificationsProvider(),
          update: (_, connectivity, notifications) {
            notifications ??= NotificationsProvider();
            notifications.attach(connectivity);
            return notifications;
          },
        ),
      ],
      child: const SchemePlusApp(),
    ),
  );
}
