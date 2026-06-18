import 'dart:convert';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/models/notification_model.dart';
import 'package:flutter_pecha/features/notifications/data/models/notification_settings_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _logger = AppLogger('NotificationLocalDataSource');

/// Local data source for notification data.
class NotificationLocalDataSource {
  static const String boxName = 'notification_data';
  static const String _settingsKey = 'notification_settings';
  static const String _scheduledNotificationsKey = 'scheduled_notifications';

  late Box<String> _box;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _box = await Hive.openBox<String>(boxName);
    _isInitialized = true;
    _logger.info('NotificationLocalDataSource initialized');
  }

  /// Ensures initialization is complete before any operation.
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) await initialize();
  }

  /// Get notification settings from local storage.
  Future<NotificationSettingsModel> getSettings() async {
    await _ensureInitialized();

    final json = _box.get(_settingsKey);
    if (json == null) {
      // Return default settings if none stored
      final defaultSettings = NotificationSettingsModel.defaultSettings();
      await saveSettings(defaultSettings);
      return defaultSettings;
    }

    try {
      return NotificationSettingsModel.fromJsonString(json);
    } catch (e) {
      _logger.error('Failed to parse notification settings', e);
      return NotificationSettingsModel.defaultSettings();
    }
  }

  /// Save notification settings to local storage.
  Future<void> saveSettings(NotificationSettingsModel settings) async {
    await _ensureInitialized();
    await _box.put(_settingsKey, settings.toJsonString());
    _logger.info('Saved notification settings');
  }

  /// Get scheduled notifications from local storage.
  Future<List<NotificationModel>> getScheduledNotifications() async {
    await _ensureInitialized();

    final json = _box.get(_scheduledNotificationsKey);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list
          .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.error('Failed to parse scheduled notifications', e);
      return [];
    }
  }

  /// Save scheduled notifications to local storage.
  Future<void> saveScheduledNotifications(List<NotificationModel> notifications) async {
    await _ensureInitialized();
    await _box.put(
      _scheduledNotificationsKey,
      jsonEncode(notifications.map((n) => n.toJson()).toList()),
    );
    _logger.info('Saved ${notifications.length} scheduled notifications');
  }

  /// Add a scheduled notification.
  Future<void> addScheduledNotification(NotificationModel notification) async {
    final notifications = await getScheduledNotifications();
    final updatedNotifications = [...notifications, notification];
    await saveScheduledNotifications(updatedNotifications);
  }

  /// Remove a scheduled notification.
  Future<void> removeScheduledNotification(String notificationId) async {
    final notifications = await getScheduledNotifications();
    final updatedNotifications = notifications.where((n) => n.id != notificationId).toList();
    await saveScheduledNotifications(updatedNotifications);
  }

  /// Clear all notification data.
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _box.delete(_settingsKey);
    await _box.delete(_scheduledNotificationsKey);
    _logger.info('Cleared all notification data');
  }
}
