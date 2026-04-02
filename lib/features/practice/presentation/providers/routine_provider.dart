import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_local_storage.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/services/routine_notification_service.dart';
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

  /// Load routines from local storage (Hive).
  Future<void> _loadRoutines() async {
    try {
      final data = await _localStorage.loadRoutine();
      if (mounted) {
        state = data;
        _logger.info('Loaded ${data.blocks.length} routine blocks from storage');
      }
    } catch (e) {
      _logger.error('Failed to load routines', e);
      if (mounted) {
        state = const RoutineData();
      }
    }
  }

  /// Save routine blocks to persistent storage and sync notifications.
  Future<void> saveRoutine(List<RoutineBlock> blocks) async {
    final data = RoutineData(blocks: blocks).sortedByTime;

    try {
      // 1. Persist to Hive storage
      await _localStorage.saveRoutine(data);
      _logger.info('Saved ${data.blocks.length} routine blocks to storage');

      // 2. Sync notifications
      await _notificationService.syncNotifications(data.blocks);

      // 3. Update in-memory state
      if (mounted) {
        state = data;
      }
    } catch (e) {
      _logger.error('Failed to save routine', e);
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
