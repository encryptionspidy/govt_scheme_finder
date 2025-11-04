import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/navigation_provider.dart';
import '../../utils/constants.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../browse/browse_screen.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    BrowseScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    final NavigationProvider navigation = context.watch<NavigationProvider>();
    final int currentIndex = navigation.currentIndex;

    void openBookmarks() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const BookmarksScreen()),
      );
    }

    void openNotifications() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      );
    }

    PreferredSizeWidget? buildAppBar() {
      if (currentIndex == 2) {
        return AppBar(
          title: Text(loc.translate('settings_title')),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.bookmark_border_rounded, size: 24),
              onPressed: openBookmarks,
              tooltip: loc.translate('bookmarks_title'),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 24),
              onPressed: openNotifications,
              tooltip: loc.translate('notifications_title'),
            ),
            const SizedBox(width: 4),
          ],
        );
      }
      return null;
    }

    return Scaffold(
      appBar: buildAppBar(),
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: dividerColor, width: 0.5)),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            height: 68,
            elevation: 0,
            backgroundColor: Colors.white,
            indicatorColor: accentLightBlue,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: <NavigationDestination>[
              NavigationDestination(
                icon: const Icon(Icons.home_outlined, size: 26),
                selectedIcon: const Icon(Icons.home_rounded, size: 26),
                label: loc.translate('nav_home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined, size: 26),
                selectedIcon: const Icon(Icons.grid_view_rounded, size: 26),
                label: loc.translate('nav_browse'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined, size: 26),
                selectedIcon: const Icon(Icons.settings_rounded, size: 26),
                label: loc.translate('nav_settings'),
              ),
            ],
            onDestinationSelected: navigation.setIndex,
          ),
        ),
      ),
    );
  }
}
