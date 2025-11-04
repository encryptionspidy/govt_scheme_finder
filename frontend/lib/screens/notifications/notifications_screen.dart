import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/notification_item.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    final NotificationsProvider provider = context.read<NotificationsProvider>();
    Future.microtask(provider.load);
  }

  Future<void> _refresh() => context.read<NotificationsProvider>().load();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    final NotificationsProvider provider = context.watch<NotificationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('notifications_title')),
        actions: <Widget>[
          if (provider.notifications.any((AppNotification n) => !n.read))
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: Text(loc.translate('mark_all_read')),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: provider.isLoading && provider.notifications.isEmpty
            ? ListView(children: <Widget>[_LoadingPlaceholder(message: loc.translate('loading'))])
            : provider.notifications.isEmpty
                ? ListView(children: <Widget>[_LoadingPlaceholder(message: loc.translate('notifications_empty'))])
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: provider.notifications.length,
                    itemBuilder: (BuildContext context, int index) {
                      final AppNotification notification = provider.notifications[index];
                      return _NotificationTile(
                        notification: notification,
                        onTap: () => provider.markAsRead(notification.id),
                      );
                    },
                  ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    final String title = loc.localizedValue(notification.title);
    final String message = loc.localizedValue(notification.message);
    final DateTime? triggerDate = notification.triggerDate;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: notification.read ? Colors.white : const Color(0xFFEAF1FF),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          notification.read ? Icons.notifications_outlined : Icons.notifications_active,
          color: const Color(0xFF176BFB),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 4),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF506197)),
            ),
            if (triggerDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${loc.translate('last_updated')}: ${triggerDate.day}/${triggerDate.month}/${triggerDate.year}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF6B7AA0)),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(notification.read ? Icons.check_circle : Icons.radio_button_unchecked,
              color: notification.read ? const Color(0xFF4CAF50) : const Color(0xFF90A4C7)),
          onPressed: onTap,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 40),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF6B7AA0)),
      ),
    );
  }
}
