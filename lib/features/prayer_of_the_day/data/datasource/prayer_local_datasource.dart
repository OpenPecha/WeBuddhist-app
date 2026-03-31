import 'dart:convert';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/data/models/prayer_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _logger = AppLogger('PrayerLocalDataSource');

/// Local data source for prayer data.
class PrayerLocalDataSource {
  static const String boxName = 'prayer_data';
  static const String _todayPrayerKey = 'today_prayer';
  static const String _completedPrayersKey = 'completed_prayers';

  late Box<String> _box;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _box = await Hive.openBox<String>(boxName);
    _isInitialized = true;
    _logger.info('PrayerLocalDataSource initialized');
  }

  /// Ensures initialization is complete before any operation.
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) await initialize();
  }

  /// Get today's prayer from local storage.
  Future<PrayerModel?> getTodayPrayer() async {
    await _ensureInitialized();

    final json = _box.get(_todayPrayerKey);
    if (json == null) return null;

    try {
      return PrayerModel.fromJsonString(json);
    } catch (e) {
      _logger.error('Failed to parse prayer data', e);
      return null;
    }
  }

  /// Save today's prayer to local storage.
  Future<void> saveTodayPrayer(PrayerModel prayer) async {
    await _ensureInitialized();
    await _box.put(_todayPrayerKey, prayer.toJsonString());
    _logger.info('Saved prayer: ${prayer.title}');
  }

  /// Get list of completed prayer IDs.
  Future<List<String>> getCompletedPrayers() async {
    await _ensureInitialized();

    final json = _box.get(_completedPrayersKey);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.cast<String>();
    } catch (e) {
      _logger.error('Failed to parse completed prayers', e);
      return [];
    }
  }

  /// Add prayer to completed list.
  Future<void> markAsCompleted(String prayerId) async {
    await _ensureInitialized();

    final completed = await getCompletedPrayers();
    if (!completed.contains(prayerId)) {
      completed.add(prayerId);
      await _box.put(_completedPrayersKey, jsonEncode(completed));
      _logger.info('Marked prayer as completed: $prayerId');
    }
  }

  /// Clear all prayer data.
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _box.delete(_todayPrayerKey);
    await _box.delete(_completedPrayersKey);
    _logger.info('Cleared all prayer data');
  }
}
