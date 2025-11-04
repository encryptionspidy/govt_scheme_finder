import 'package:hive/hive.dart';

import '../local/hive_boxes.dart';
import '../models/notification_item.dart';
import '../services/api_service.dart';

class NotificationRepository {
  NotificationRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Box get _box => Hive.box(HiveBoxes.notifications);

  Future<List<AppNotification>> fetchNotifications({required bool networkAvailable}) async {
    const String key = 'notifications';
    if (networkAvailable) {
      try {
        final List<AppNotification> remote = await _apiService.fetchNotifications();
        await _box.put(
          key,
          remote.map((AppNotification n) => n.toMap()).toList(),
        );
        return remote;
      } catch (_) {
        return _readCached(key);
      }
    }
    return _readCached(key);
  }

  Future<void> saveNotifications(List<AppNotification> notifications) async {
    const String key = 'notifications';
    await _box.put(
      key,
      notifications.map((AppNotification n) => n.toMap()).toList(),
    );
  }

  List<AppNotification> _readCached(String key) {
    final List<dynamic>? cached = _box.get(key) as List?;
    if (cached == null) return <AppNotification>[];
    return cached
        .map((dynamic item) =>
            AppNotification.fromMap((item as Map).cast<String, dynamic>()))
        .toList();
  }
}
