import 'dart:convert';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _logger = AppLogger('RoutineLocalStorage');

/// Dedicated Hive storage for routine data.
/// This is persistent local user data with full CRUD — NOT a cache with TTL.
class RoutineLocalStorage {
  static const String boxName = 'routine_data';
  static const String _routineKey = 'user_routine';

  late Box<String> _box;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _box = await Hive.openBox<String>(boxName);
    _isInitialized = true;
    _logger.info('RoutineLocalStorage initialized');
  }

  /// READ: Load persisted routine. Returns empty RoutineData if none saved.
  RoutineData loadRoutine() {
    final json = _box.get(_routineKey);
    if (json == null) return const RoutineData();
    try {
      return RoutineData.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (e) {
      _logger.error('Failed to parse routine data', e);
      return const RoutineData();
    }
  }

  /// CREATE / UPDATE: Persist routine data to Hive.
  Future<void> saveRoutine(RoutineData data) async {
    await _box.put(_routineKey, jsonEncode(data.toJson()));
    _logger.info('Routine saved (${data.blocks.length} blocks)');
  }

  /// DELETE: Remove all routine data from Hive.
  Future<void> clearRoutine() async {
    await _box.delete(_routineKey);
    _logger.info('Routine data cleared');
  }
}
