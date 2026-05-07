import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';

/// Everything in this state is a live read of an OS-level setting.
/// The app never stores its own copy — toggling a switch just redirects the
/// user to the matching system settings page, and [refreshStatus] reloads
/// the truth when they return.
class NotificationState {
  final bool isLoading;
  final bool hasSystemPermission;
  final bool routineChannelEnabled;
  final bool canScheduleExactAlarms;
  final bool isBatteryOptimizationExempt;

  const NotificationState({
    this.isLoading = false,
    this.hasSystemPermission = false,
    this.routineChannelEnabled = false,
    this.canScheduleExactAlarms = true,
    this.isBatteryOptimizationExempt = true,
  });

  NotificationState copyWith({
    bool? isLoading,
    bool? hasSystemPermission,
    bool? routineChannelEnabled,
    bool? canScheduleExactAlarms,
    bool? isBatteryOptimizationExempt,
  }) =>
      NotificationState(
        isLoading: isLoading ?? this.isLoading,
        hasSystemPermission: hasSystemPermission ?? this.hasSystemPermission,
        routineChannelEnabled:
            routineChannelEnabled ?? this.routineChannelEnabled,
        canScheduleExactAlarms:
            canScheduleExactAlarms ?? this.canScheduleExactAlarms,
        isBatteryOptimizationExempt:
            isBatteryOptimizationExempt ?? this.isBatteryOptimizationExempt,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;

  NotificationNotifier(this._service) : super(const NotificationState()) {
    refreshStatus(initial: true);
  }

  /// Re-reads every OS-level permission state.
  /// Called on init, and whenever the app resumes from a system Settings page.
  Future<void> refreshStatus({bool initial = false}) async {
    if (initial) state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _service.areNotificationsEnabled(),
        _service.isChannelEnabled(NotificationChannels.routineBlockId),
        _service.canScheduleExactNotifications(),
        _service.isBatteryOptimizationExempt(),
      ]);
      state = state.copyWith(
        hasSystemPermission: results[0],
        routineChannelEnabled: results[1],
        canScheduleExactAlarms: results[2],
        isBatteryOptimizationExempt: results[3],
        isLoading: false,
      );
    } catch (_) {
      if (initial) state = state.copyWith(isLoading: false);
    }
  }

  /// Shows the Android/iOS system permission dialog. Returns false if the
  /// user denied (or the OS silently declined because the dialog was already
  /// dismissed before).
  Future<bool> requestEnableNotifications() async {
    final granted = await _service.requestPermission();
    state = state.copyWith(hasSystemPermission: granted);
    // Also re-read the channel state — channels default to enabled on grant.
    if (granted) {
      final channelEnabled = await _service
          .isChannelEnabled(NotificationChannels.routineBlockId);
      state = state.copyWith(routineChannelEnabled: channelEnabled);
    }
    return granted;
  }

  /// Re-syncs scheduled routine notifications. Use after returning from
  /// system settings in case the user re-enabled the channel.
  Future<void> resyncRoutineNotifications(List<RoutineBlock> blocks) async {
    await RoutineNotificationService().syncNotifications(blocks);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(NotificationService());
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
