import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

/// Simplified notification state - only tracks permission status
class NotificationState {
  final bool isLoading;
  final bool hasPermission;

  const NotificationState({
    this.isLoading = false,
    this.hasPermission = false,
  });

  NotificationState copyWith({
    bool? isLoading,
    bool? hasPermission,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

/// Simplified notifier - only manages permission status
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;

  NotificationNotifier(this._notificationService)
    : super(const NotificationState()) {
    _loadPermissionStatus();
  }

  Future<void> _loadPermissionStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final hasPermission =
          await _notificationService.areNotificationsEnabled();

      state = state.copyWith(
        hasPermission: hasPermission,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> checkPermissionStatus() async {
    final hasPermission = await _notificationService.areNotificationsEnabled();
    state = state.copyWith(hasPermission: hasPermission);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier(NotificationService());
    });

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
