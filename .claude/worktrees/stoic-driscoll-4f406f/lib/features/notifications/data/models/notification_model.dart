import 'dart:convert';

import 'package:flutter_pecha/features/notifications/domain/entities/notification.dart';

/// Notification data model with JSON serialization.
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final NotificationType type;
  final bool isRecurring;
  final String? recurrencePattern;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.type,
    this.isRecurring = false,
    this.recurrencePattern,
  });

  /// Convert AppNotification entity to NotificationModel.
  static NotificationModel fromEntity(AppNotification entity) {
    return NotificationModel(
      id: entity.id,
      title: entity.title,
      body: entity.body,
      scheduledTime: entity.scheduledTime,
      type: entity.type,
      isRecurring: entity.isRecurring,
      recurrencePattern: entity.recurrencePattern,
    );
  }

  /// Convert NotificationModel to AppNotification entity.
  AppNotification toEntity() {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      type: type,
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'scheduledTime': scheduledTime.toIso8601String(),
        'type': type.name,
        'isRecurring': isRecurring,
        'recurrencePattern': recurrencePattern,
      };

  /// Deserialize from JSON.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.practiceReminder,
      ),
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrencePattern: json['recurrencePattern'] as String?,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string.
  factory NotificationModel.fromJsonString(String jsonString) {
    return NotificationModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
