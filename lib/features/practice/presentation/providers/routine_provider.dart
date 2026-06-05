import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_local_storage.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart'
    show routineLocalStorageProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('RoutineNotifier');

/// Provider for RoutineNotifier with persistent storage.
///
/// Uses RoutineLocalStorage (Hive) for persistence and
/// [NotificationSyncEngine] for notification scheduling.
final routineProvider = StateNotifierProvider<RoutineNotifier, RoutineData>((ref) {
  final localStorage = ref.watch(routineLocalStorageProvider);
  final analyticsService = ref.watch(analyticsServiceProvider);
  return RoutineNotifier(
    localStorage: localStorage,
    syncEngine: () => ref.read(notificationSyncEngineProvider),
    analyticsService: analyticsService,
  );
});

class RoutineNotifier extends StateNotifier<RoutineData> {
  final RoutineLocalStorage _localStorage;
  final NotificationSyncEngine Function() _syncEngine;
  final AnalyticsService _analyticsService;

  RoutineNotifier({
    required RoutineLocalStorage localStorage,
    required NotificationSyncEngine Function() syncEngine,
    required AnalyticsService analyticsService,
  })  : _localStorage = localStorage,
        _syncEngine = syncEngine,
        _analyticsService = analyticsService,
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
          final report =
              await _syncEngine().sync(trigger: SyncTrigger.coldStart);
          _logger.info('[ROUTINE-LOAD] Startup sync done: $report');
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
  ///
  /// Convenience for non-latency-sensitive callers (e.g. background enrolment,
  /// reorder ops). Latency-sensitive UI flows (e.g. Edit Routine → "Done")
  /// should call [saveRoutineLocalOnly] and run [syncNotifications]
  /// unawaited so the slow notification reschedule never blocks navigation.
  Future<void> saveRoutine(List<RoutineBlock> blocks) async {
    await saveRoutineLocalOnly(blocks);
    await syncNotifications(blocks);
  }

  /// Persists [blocks] to Hive and updates in-memory state. Fast (~ms).
  ///
  /// Does NOT touch OS notifications — see [syncNotifications]. Splitting
  /// these lets the UI navigate away the moment local state is durable,
  /// while the (slow) platform-channel notification work continues in the
  /// background.
  Future<void> saveRoutineLocalOnly(List<RoutineBlock> blocks) async {
    final data = RoutineData(blocks: blocks).sortedByTime;
    _logger.info('[ROUTINE-SAVE] persisting ${data.blocks.length} blocks (local only)');
    try {
      await _localStorage.saveRoutine(data);
      if (mounted) {
        state = data;
      }

      final int itemCount = data.blocks.fold<int>(
        0,
        (int sum, RoutineBlock block) => sum + block.items.length,
      );
      await _analyticsService.track(
        AnalyticsEvents.routineSaved,
        properties: {
          AnalyticsProperties.blockCount: data.blocks.length,
          AnalyticsProperties.itemCount: itemCount,
        },
      );
    } catch (e) {
      _logger.error('[ROUTINE-SAVE] local persist failed', e);
      rethrow;
    }
  }

  /// Reschedules OS notifications to match the current routine.
  ///
  /// The `blocks` argument is accepted for backwards-compatibility with
  /// existing callers (e.g. [`EditRoutineScreen._saveAndPop`]); the engine
  /// reads routine state from [routineProvider] internally, so the argument
  /// is intentionally unused — the caller's earlier `saveRoutineLocalOnly`
  /// call has already written the new state.
  Future<void> syncNotifications(List<RoutineBlock> blocks) async {
    _logger.info('[ROUTINE-SAVE] delegating to NotificationSyncEngine');
    final report = await _syncEngine().sync(trigger: SyncTrigger.routineSaved);
    _logger.info('[ROUTINE-SAVE] sync done: $report');
  }

  /// Clear all routine data from storage and cancel notifications.
  Future<void> clearRoutine() async {
    try {
      // 1. Clear from Hive storage so the engine sees empty routine.
      await _localStorage.clearRoutine();
      _logger.info('Cleared all routine data from storage');

      // 2. Update in-memory state.
      if (mounted) {
        state = const RoutineData();
      }

      // 3. Run reconciliation — pending IDs go away because the desired set
      //    is now empty.
      await _syncEngine().sync(trigger: SyncTrigger.routineSaved);
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
