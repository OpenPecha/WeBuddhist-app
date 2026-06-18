import 'package:equatable/equatable.dart';

/// Notification settings entity.
class NotificationSettings extends Equatable {
  final bool enabled;
  final bool practiceReminders;
  final bool planReminders;
  final bool newContentAlerts;
  final String practiceTime; // HH:MM format

  const NotificationSettings({
    required this.enabled,
    required this.practiceReminders,
    required this.planReminders,
    required this.newContentAlerts,
    required this.practiceTime,
  });

  @override
  List<Object?> get props => [enabled, practiceReminders, planReminders, newContentAlerts, practiceTime];
}
