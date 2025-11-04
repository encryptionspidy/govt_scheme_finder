// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:provider/provider.dart';

import 'package:schemeplus_app/app.dart';
import 'package:schemeplus_app/data/local/hive_boxes.dart';
import 'package:schemeplus_app/providers/app_language_provider.dart';
import 'package:schemeplus_app/providers/user_profile_provider.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    await Hive.openBox(HiveBoxes.bookmarks);
    await Hive.openBox(HiveBoxes.schemesCache);
    await Hive.openBox(HiveBoxes.profile);
    await Hive.openBox(HiveBoxes.notifications);
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  testWidgets('App renders splash screen title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: <ChangeNotifierProvider<dynamic>>[
          ChangeNotifierProvider<AppLanguageProvider>(
            create: (_) => AppLanguageProvider(),
          ),
          ChangeNotifierProvider<UserProfileProvider>(
            create: (_) => UserProfileProvider(),
          ),
        ],
        child: const SchemePlusApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('SchemePlus'), findsOneWidget);
  });
}
