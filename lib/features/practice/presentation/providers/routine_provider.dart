import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
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
  final analyticsService = ref.watch(analyticsServiceProvider);
  return RoutineNotifier(
    localStorage: localStorage,
    notificationService: notificationService,
    analyticsService: analyticsService,
  );
});

class RoutineNotifier extends StateNotifier<RoutineData> {
  final RoutineLocalStorage _localStorage;
  final RoutineNotificationService _notificationService;
  final AnalyticsService _analyticsService;

  RoutineNotifier({
    required RoutineLocalStorage localStorage,
    required RoutineNotificationService notificationService,
    required AnalyticsService analyticsService,
  })  : _localStorage = localStorage,
        _notificationService = notificationService,
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

  /// Reschedules OS notifications to match [blocks].
  ///
  /// Can be slow on plan blocks (60+ sequential platform-channel
  /// cancel/schedule calls per plan). Safe to run unawaited from UI flows;
  /// the startup bootstrap re-syncs on next launch so failures here are
  /// recoverable.
  Future<void> syncNotifications(List<RoutineBlock> blocks) async {
    _logger.info('[ROUTINE-SAVE] syncing notifications for ${blocks.length} blocks');
    final result = await _notificationService.syncNotifications(blocks);
    _logger.info(
      '[ROUTINE-SAVE] sync done: scheduled=${result.scheduled} '
      'cancelled=${result.cancelled} failed=${result.failed} '
      'errors=${result.errors}',
    );
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
