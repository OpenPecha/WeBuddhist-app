import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Routine entity for practice tracking.
class Routine extends BaseEntity {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final RoutineType type;
  final List<TimeSlot> timeSlots;
  final bool isActive;
  final int streakCount;

  const Routine({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.type,
    this.timeSlots = const [],
    this.isActive = true,
    this.streakCount = 0,
  });

  @override
  List<Object?> get props => [id, name, description, durationMinutes, type, timeSlots, isActive, streakCount];
}

/// Type of practice routine.
enum RoutineType {
  morning,
  afternoon,
  evening,
  custom,
}

/// Time slot for a routine.
class TimeSlot extends Equatable {
  final int hour;
  final int minute;
  final List<int> days; // 0-6, where 0 is Monday

  const TimeSlot({
    required this.hour,
    required this.minute,
    this.days = const [],
  });

  @override
  List<Object?> get props => [hour, minute, days];
}
