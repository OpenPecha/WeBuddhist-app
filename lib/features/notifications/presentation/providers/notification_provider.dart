import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_provider.dart';

final _logger = AppLogger('NotificationProvider');

enum NotificationToggleResult { success, permissionDenied, error }

// ─── Block-type helpers ───────────────────────────────────────────────────────

bool _isRoutineBlock(RoutineBlock block) =>
    block.items.firstOrNull?.type == RoutineItemType.plan;

bool _isRecitationBlock(RoutineBlock block) =>
    block.items.firstOrNull?.type == RoutineItemType.recitation;

// ─────────────────────────────────────────────────────────────────────────────

/// Three app-level flags (master / routine / recitation) are stored in
/// SharedPreferences and never touch OS permission. OS-level checks
/// (system permission, exact alarms, battery) are read-only live reads.
class NotificationState {
  final bool isLoading;
  final bool appMasterEnabled;
  final bool appRoutineEnabled;
  final bool appRecitationEnabled;
  final bool hasSystemPermission;
  final bool canScheduleExactAlarms;
  final bool isBatteryOptimizationExempt;

  const NotificationState({
    this.isLoading = false,
    this.appMasterEnabled = true,
    this.appRoutineEnabled = true,
    this.appRecitationEnabled = true,
    this.hasSystemPermission = false,
    this.canScheduleExactAlarms = true,
    this.isBatteryOptimizationExempt = true,
  });

  NotificationState copyWith({
    bool? isLoading,
    bool? appMasterEnabled,
    bool? appRoutineEnabled,
    bool? appRecitationEnabled,
    bool? hasSystemPermission,
    bool? canScheduleExactAlarms,
    bool? isBatteryOptimizationExempt,
  }) =>
      NotificationState(
        isLoading: isLoading ?? this.isLoading,
        appMasterEnabled: appMasterEnabled ?? this.appMasterEnabled,
        appRoutineEnabled: appRoutineEnabled ?? this.appRoutineEnabled,
        appRecitationEnabled: appRecitationEnabled ?? this.appRecitationEnabled,
        hasSystemPermission: hasSystemPermission ?? this.hasSystemPermission,
        canScheduleExactAlarms:
            canScheduleExactAlarms ?? this.canScheduleExactAlarms,
        isBatteryOptimizationExempt:
            isBatteryOptimizationExempt ?? this.isBatteryOptimizationExempt,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;
  final Ref _ref;

  NotificationNotifier(this._service, this._ref)
      : super(const NotificationState()) {
    refreshStatus(initial: true);
  }

  /// Re-reads OS-level permissions and SharedPreferences flags in parallel.
  /// Called on init and on app resume from a Settings page.
  Future<void> refreshStatus({bool initial = false}) async {
    if (initial) state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait<bool>([
        _service.areNotificationsEnabled(),
        _service.canScheduleExactNotifications(),
        _service.isBatteryOptimizationExempt(),
        _loadBool(StorageKeys.notificationMasterEnabled, defaultValue: true),
        _loadBool(StorageKeys.notificationRoutineEnabled, defaultValue: true),
        _loadBool(StorageKeys.notificationRecitationEnabled, defaultValue: true),
      ]);
      state = state.copyWith(
        hasSystemPermission: results[0],
        canScheduleExactAlarms: results[1],
        isBatteryOptimizationExempt: results[2],
        appMasterEnabled: results[3],
        appRoutineEnabled: results[4],
        appRecitationEnabled: results[5],
        isLoading: false,
      );
    } catch (_) {
      if (initial) state = state.copyWith(isLoading: false);
    }
  }

  // ── Master toggle ───────────────────────────────────────────────────────────

  /// Toggles the master in-app notification switch.
  ///
  /// Optimistic update: UI reflects the new value instantly. On failure the
  /// previous state is restored and [NotificationToggleResult.error] is
  /// returned so the caller can show a localised error snack.
  ///
  /// ON  → requests OS permission if missing, then syncs notifications
  ///        respecting each sub-toggle's current saved state.
  /// OFF → cancels every scheduled notification (routine + recitation +
  ///        special-plan series + duration series). Sub-toggle states are
  ///        preserved in SharedPreferences so re-enabling restores them.
  Future<NotificationToggleResult> toggleMaster(bool enable) async {
    _logger.info('[TOGGLE] master → $enable '
        '(routine=${state.appRoutineEnabled} recitation=${state.appRecitationEnabled} '
        'osPermission=${state.hasSystemPermission})');
    final previous = state;
    state = state.copyWith(appMasterEnabled: enable);

    try {
      final prefs = await SharedPreferences.getInstance();

      if (enable) {
        if (!state.hasSystemPermission) {
          _logger.info('[TOGGLE] master ON — OS permission missing, requesting…');
          final granted = await _service.requestPermission();
          if (!granted) {
            _logger.warning('[TOGGLE] master ON — OS permission denied, reverting');
            state = previous.copyWith(appMasterEnabled: false);
            await prefs.setBool(StorageKeys.notificationMasterEnabled, false);
            return NotificationToggleResult.permissionDenied;
          }
          _logger.info('[TOGGLE] master ON — OS permission granted');
          state = state.copyWith(hasSystemPermission: true);
        }
        await prefs.setBool(StorageKeys.notificationMasterEnabled, true);
        final blocks = _ref.read(routineProvider).blocks;
        _logger.info('[TOGGLE] master ON — syncing ${blocks.length} block(s) by sub-toggle state');
        await _syncBySubToggles(blocks);
      } else {
        await prefs.setBool(StorageKeys.notificationMasterEnabled, false);
        final blocks = _ref.read(routineProvider).blocks;
        _logger.info('[TOGGLE] master OFF — cancelling all notifications (${blocks.length} block(s))');
        await _cancelAll(blocks);
      }

      _logger.info('[TOGGLE] master → $enable COMPLETE');
      return NotificationToggleResult.success;
    } catch (e, st) {
      _logger.error('[TOGGLE] master → $enable FAILED — reverting', e, st);
      state = previous;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
            StorageKeys.notificationMasterEnabled, previous.appMasterEnabled);
      } catch (_) {}
      return NotificationToggleResult.error;
    }
  }

  // ── Sub-toggles ─────────────────────────────────────────────────────────────

  /// Toggles routine (plan) block notifications independently.
  ///
  /// ON  → re-schedules only plan blocks (includes special-plan and
  ///        duration series via [syncNotifications]).
  /// OFF → cancels plan block notifications, special-plan series, and
  ///        duration series. Routine blocks are NOT affected.
  Future<NotificationToggleResult> toggleRoutine(bool enable) async {
    _logger.info('[TOGGLE] routine → $enable');
    final previous = state;
    state = state.copyWith(appRoutineEnabled: enable);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.notificationRoutineEnabled, enable);

      final allBlocks = _ref.read(routineProvider).blocks;
      final routineBlocks = allBlocks.where(_isRoutineBlock).toList();
      _logger.info('[TOGGLE] routine — ${routineBlocks.length} plan block(s) found');
      final svc = RoutineNotificationService();

      if (enable) {
        _logger.info('[TOGGLE] routine ON — scheduling plan blocks + series');
        await svc.syncNotifications(routineBlocks);
      } else {
        _logger.info('[TOGGLE] routine OFF — cancelling plan blocks, special-plan series, duration series');
        await svc.cancelAllBlockNotifications(routineBlocks);
        await svc.cancelAllSpecialPlanSchedules();
        await svc.cancelAllPlanDurationSchedules();
      }

      _logger.info('[TOGGLE] routine → $enable COMPLETE');
      return NotificationToggleResult.success;
    } catch (e, st) {
      _logger.error('[TOGGLE] routine → $enable FAILED — reverting', e, st);
      state = previous;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
            StorageKeys.notificationRoutineEnabled, previous.appRoutineEnabled);
      } catch (_) {}
      return NotificationToggleResult.error;
    }
  }

  /// Toggles recitation block notifications independently.
  ///
  /// ON  → re-schedules only recitation blocks.
  /// OFF → cancels only recitation blocks. Plan blocks are NOT affected.
  Future<NotificationToggleResult> toggleRecitation(bool enable) async {
    _logger.info('[TOGGLE] recitation → $enable');
    final previous = state;
    state = state.copyWith(appRecitationEnabled: enable);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.notificationRecitationEnabled, enable);

      final allBlocks = _ref.read(routineProvider).blocks;
      final recitationBlocks = allBlocks.where(_isRecitationBlock).toList();
      _logger.info('[TOGGLE] recitation — ${recitationBlocks.length} recitation block(s) found');
      final svc = RoutineNotificationService();

      if (enable) {
        _logger.info('[TOGGLE] recitation ON — scheduling recitation blocks');
        await svc.syncNotifications(recitationBlocks);
      } else {
        _logger.info('[TOGGLE] recitation OFF — cancelling recitation blocks');
        await svc.cancelAllBlockNotifications(recitationBlocks);
      }

      _logger.info('[TOGGLE] recitation → $enable COMPLETE');
      return NotificationToggleResult.success;
    } catch (e, st) {
      _logger.error('[TOGGLE] recitation → $enable FAILED — reverting', e, st);
      state = previous;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(StorageKeys.notificationRecitationEnabled,
            previous.appRecitationEnabled);
      } catch (_) {}
      return NotificationToggleResult.error;
    }
  }

  // ── Resume sync ─────────────────────────────────────────────────────────────

  /// Called when the app resumes from system settings. Re-syncs only if the
  /// master toggle is on, respecting each sub-toggle's saved state.
  Future<void> resyncRoutineNotifications(List<RoutineBlock> blocks) async {
    if (!state.appMasterEnabled) return;
    await _syncBySubToggles(blocks);
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Schedules/cancels each block category according to its sub-toggle state.
  Future<void> _syncBySubToggles(List<RoutineBlock> blocks) async {
    final svc = RoutineNotificationService();
    final routineBlocks = blocks.where(_isRoutineBlock).toList();
    final recitationBlocks = blocks.where(_isRecitationBlock).toList();

    _logger.info(
      '[SYNC] _syncBySubToggles — '
      'routineBlocks=${routineBlocks.length} appRoutineEnabled=${state.appRoutineEnabled} | '
      'recitationBlocks=${recitationBlocks.length} appRecitationEnabled=${state.appRecitationEnabled}',
    );

    if (state.appRoutineEnabled) {
      _logger.info('[SYNC] scheduling ${routineBlocks.length} routine block(s)');
      await svc.syncNotifications(routineBlocks);
    } else {
      _logger.info('[SYNC] routine disabled — cancelling plan blocks + series');
      await svc.cancelAllBlockNotifications(routineBlocks);
      await svc.cancelAllSpecialPlanSchedules();
      await svc.cancelAllPlanDurationSchedules();
    }

    if (state.appRecitationEnabled) {
      _logger.info('[SYNC] scheduling ${recitationBlocks.length} recitation block(s)');
      await svc.syncNotifications(recitationBlocks);
    } else {
      _logger.info('[SYNC] recitation disabled — cancelling recitation blocks');
      await svc.cancelAllBlockNotifications(recitationBlocks);
    }

    _logger.info('[SYNC] _syncBySubToggles DONE');
  }

  /// Cancels every scheduled notification regardless of sub-toggle states.
  Future<void> _cancelAll(List<RoutineBlock> blocks) async {
    _logger.info('[CANCEL-ALL] cancelling ${blocks.length} block(s) + all series');
    final svc = RoutineNotificationService();
    await svc.cancelAllBlockNotifications(blocks);
    await svc.cancelAllSpecialPlanSchedules();
    await svc.cancelAllPlanDurationSchedules();
    await _service.notificationsPlugin.cancel(_kDiagnosticTestNotifId);
    _logger.info('[CANCEL-ALL] DONE');
  }

  static const int _kDiagnosticTestNotifId = 9999;

  Future<bool> _loadBool(String key, {required bool defaultValue}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(NotificationService(), ref);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
