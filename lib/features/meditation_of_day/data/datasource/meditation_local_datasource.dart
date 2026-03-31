import 'dart:convert';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/meditation_of_day/data/models/meditation_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _logger = AppLogger('MeditationLocalDataSource');

/// Local data source for meditation data.
class MeditationLocalDataSource {
  static const String boxName = 'meditation_data';
  static const String _todayMeditationKey = 'today_meditation';
  static const String _completedMeditationsKey = 'completed_meditations';

  late Box<String> _box;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _box = await Hive.openBox<String>(boxName);
    _isInitialized = true;
    _logger.info('MeditationLocalDataSource initialized');
  }

  /// Ensures initialization is complete before any operation.
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) await initialize();
  }

  /// Get today's meditation from local storage.
  Future<MeditationModel?> getTodayMeditation() async {
    await _ensureInitialized();

    final json = _box.get(_todayMeditationKey);
    if (json == null) return null;

    try {
      return MeditationModel.fromJsonString(json);
    } catch (e) {
      _logger.error('Failed to parse meditation data', e);
      return null;
    }
  }

  /// Save today's meditation to local storage.
  Future<void> saveTodayMeditation(MeditationModel meditation) async {
    await _ensureInitialized();
    await _box.put(_todayMeditationKey, meditation.toJsonString());
    _logger.info('Saved meditation: ${meditation.title}');
  }

  /// Get list of completed meditation IDs.
  Future<List<String>> getCompletedMeditations() async {
    await _ensureInitialized();

    final json = _box.get(_completedMeditationsKey);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.cast<String>();
    } catch (e) {
      _logger.error('Failed to parse completed meditations', e);
      return [];
    }
  }

  /// Add meditation to completed list.
  Future<void> markAsCompleted(String meditationId) async {
    await _ensureInitialized();

    final completed = await getCompletedMeditations();
    if (!completed.contains(meditationId)) {
      completed.add(meditationId);
      await _box.put(_completedMeditationsKey, jsonEncode(completed));
      _logger.info('Marked meditation as completed: $meditationId');
    }
  }

  /// Clear all meditation data.
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _box.delete(_todayMeditationKey);
    await _box.delete(_completedMeditationsKey);
    _logger.info('Cleared all meditation data');
  }
}
