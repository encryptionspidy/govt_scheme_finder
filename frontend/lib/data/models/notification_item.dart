class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.schemeId,
    required this.title,
    required this.message,
    required this.triggerDate,
    this.read = false,
  });

  final String id;
  final String type;
  final String schemeId;
  final Map<String, dynamic> title;
  final Map<String, dynamic> message;
  final DateTime? triggerDate;
  final bool read;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'schemeId': schemeId,
        'title': title,
        'message': message,
        'triggerDate': triggerDate?.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return AppNotification(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'general',
      schemeId: map['schemeId']?.toString() ?? '',
      title: Map<String, dynamic>.from(map['title'] as Map),
      message: Map<String, dynamic>.from(map['message'] as Map),
      triggerDate: parseDate(map['triggerDate']),
      read: map['read'] as bool? ?? false,
    );
  }

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        schemeId: schemeId,
        title: title,
        message: message,
        triggerDate: triggerDate,
        read: read ?? this.read,
      );
}
