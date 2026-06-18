import 'dart:convert';

import 'package:flutter_pecha/features/notifications/domain/entities/notification_settings.dart';

/// Notification settings data model with JSON serialization.
class NotificationSettingsModel {
  final bool enabled;
  final bool practiceReminders;
  final bool planReminders;
  final bool newContentAlerts;
  final String practiceTime; // HH:MM format

  const NotificationSettingsModel({
    required this.enabled,
    required this.practiceReminders,
    required this.planReminders,
    required this.newContentAlerts,
    required this.practiceTime,
  });

  /// Convert NotificationSettings entity to NotificationSettingsModel.
  static NotificationSettingsModel fromEntity(NotificationSettings entity) {
    return NotificationSettingsModel(
      enabled: entity.enabled,
      practiceReminders: entity.practiceReminders,
      planReminders: entity.planReminders,
      newContentAlerts: entity.newContentAlerts,
      practiceTime: entity.practiceTime,
    );
  }

  /// Convert NotificationSettingsModel to NotificationSettings entity.
  NotificationSettings toEntity() {
    return NotificationSettings(
      enabled: enabled,
      practiceReminders: practiceReminders,
      planReminders: planReminders,
      newContentAlerts: newContentAlerts,
      practiceTime: practiceTime,
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'practiceReminders': practiceReminders,
        'planReminders': planReminders,
        'newContentAlerts': newContentAlerts,
        'practiceTime': practiceTime,
      };

  /// Deserialize from JSON.
  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      enabled: json['enabled'] as bool? ?? true,
      practiceReminders: json['practiceReminders'] as bool? ?? true,
      planReminders: json['planReminders'] as bool? ?? true,
      newContentAlerts: json['newContentAlerts'] as bool? ?? true,
      practiceTime: json['practiceTime'] as String? ?? '07:00',
    );
  }

  /// Get default settings.
  factory NotificationSettingsModel.defaultSettings() {
    return const NotificationSettingsModel(
      enabled: true,
      practiceReminders: true,
      planReminders: true,
      newContentAlerts: true,
      practiceTime: '07:00',
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string.
  factory NotificationSettingsModel.fromJsonString(String jsonString) {
    return NotificationSettingsModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
