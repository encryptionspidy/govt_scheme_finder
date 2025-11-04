import 'package:flutter/material.dart';

import '../data/models/notification_item.dart';
import '../data/repositories/notification_repository.dart';
import 'connectivity_provider.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider() : _repository = NotificationRepository();

  final NotificationRepository _repository;
  ConnectivityProvider? _connectivityProvider;

  List<AppNotification> _notifications = <AppNotification>[];
  bool _loading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _loading;
  String? get error => _error;

  void attach(ConnectivityProvider provider) {
    _connectivityProvider = provider;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final List<AppNotification> data = await _repository.fetchNotifications(
        networkAvailable: _connectivityProvider?.isOnline ?? true,
      );
      _notifications = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final int index = _notifications.indexWhere((AppNotification n) => n.id == id);
    if (index == -1) return;
    _notifications = List<AppNotification>.from(_notifications)
      ..[index] = _notifications[index].copyWith(read: true);
    await _repository.saveNotifications(_notifications);
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((AppNotification n) => n.copyWith(read: true)).toList();
    await _repository.saveNotifications(_notifications);
    notifyListeners();
  }
}
