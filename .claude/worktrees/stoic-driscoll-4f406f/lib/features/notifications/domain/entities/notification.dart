import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Notification entity.
class AppNotification extends BaseEntity {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final NotificationType type;
  final bool isRecurring;
  final String? recurrencePattern;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.type,
    this.isRecurring = false,
    this.recurrencePattern,
  });

  @override
  List<Object?> get props => [id, title, body, scheduledTime, type, isRecurring, recurrencePattern];
}

enum NotificationType { practiceReminder, planReminder, newContent, announcement }
