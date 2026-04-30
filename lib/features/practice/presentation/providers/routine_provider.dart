import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_local_storage.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('RoutineNotifier');

/// Provider for RoutineNotifier with persistent storage.
///
/// Uses RoutineLocalStorage (Hive) for persistence and
/// RoutineNotificationService for notification scheduling.
final routineProvider = StateNotifierProvider<RoutineNotifier, RoutineData>((ref) {
  final localStorage = ref.watch(routineLocalStorageProvider);
  final notificationService = ref.watch(routineNotificationServiceProvider);
  return RoutineNotifier(
    localStorage: localStorage,
    notificationService: notificationService,
  );
});

class RoutineNotifier extends StateNotifier<RoutineData> {
  final RoutineLocalStorage _localStorage;
  final RoutineNotificationService _notificationService;

  RoutineNotifier({
    required RoutineLocalStorage localStorage,
    required RoutineNotificationService notificationService,
  })  : _localStorage = localStorage,
        _notificationService = notificationService,
        super(const RoutineData()) {
    _loadRoutines();
  }

  /// Load routines from local storage (Hive) and re-sync notifications.
  /// Re-syncing on startup ensures alarms are registered even after app
  /// updates or edge cases where AlarmManager entries were cleared.
  Future<void> _loadRoutines() async {
    try {
      final data = await _localStorage.loadRoutine();
      if (mounted) {
        state = data;
        _logger.info('[ROUTINE-LOAD] Loaded ${data.blocks.length} blocks from storage');
        if (data.blocks.isNotEmpty) {
          _logger.info('[ROUTINE-LOAD] Re-syncing ${data.blocks.length} notifications on startup...');
          final result = await _notificationService.syncNotifications(data.blocks);
          _logger.info(
            '[ROUTINE-LOAD] Startup sync done: scheduled=${result.scheduled} '
            'cancelled=${result.cancelled} failed=${result.failed}',
          );
        }
      }
    } catch (e) {
      _logger.error('[ROUTINE-LOAD] Failed to load routines', e);
      if (mounted) {
        state = const RoutineData();
      }
    }
  }

  /// Save routine blocks to persistent storage and sync notifications.
  Future<void> saveRoutine(List<RoutineBlock> blocks) async {
    final data = RoutineData(blocks: blocks).sortedByTime;
    _logger.info('[ROUTINE-SAVE] saving ${data.blocks.length} blocks');

    try {
      // 1. Persist to Hive storage
      await _localStorage.saveRoutine(data);
      _logger.info('[ROUTINE-SAVE] persisted to storage');

      // 2. Sync notifications
      _logger.info('[ROUTINE-SAVE] calling syncNotifications...');
      final syncResult = await _notificationService.syncNotifications(data.blocks);
      _logger.info(
        '[ROUTINE-SAVE] sync done: scheduled=${syncResult.scheduled} '
        'cancelled=${syncResult.cancelled} failed=${syncResult.failed} '
        'errors=${syncResult.errors}',
      );

      // 3. Update in-memory state
      if (mounted) {
        state = data;
      }
    } catch (e) {
      _logger.error('[ROUTINE-SAVE] failed', e);
      rethrow;
    }
  }

  /// Clear all routine data from storage and cancel notifications.
  Future<void> clearRoutine() async {
    try {
      // 1. Cancel all notifications first
      await _notificationService.cancelAllBlockNotifications(state.blocks);

      // 2. Clear from Hive storage
      await _localStorage.clearRoutine();
      _logger.info('Cleared all routine data from storage');

      // 3. Update in-memory state
      if (mounted) {
        state = const RoutineData();
      }
    } catch (e) {
      _logger.error('Failed to clear routine', e);
      rethrow;
    }
  }

  /// Reorder items within a specific block and persist.
  Future<void> reorderItemsInBlock(
    String blockId,
    int oldIndex,
    int newIndex,
  ) async {
    final blocks = state.blocks.map((block) {
      if (block.id != blockId) return block;
      final items = List<RoutineItem>.from(block.items);
      final item = items.removeAt(oldIndex);
      final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      items.insert(adjustedIndex, item);
      return block.copyWith(items: items);
    }).toList();
    await saveRoutine(blocks);
  }

  /// Refresh routine data from storage.
  Future<void> refresh() async {
    await _loadRoutines();
  }
}
