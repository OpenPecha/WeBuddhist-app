import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Practice session entity representing a completed practice session.
class PracticeSession extends BaseEntity {
  final String id;
  final String routineId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final SessionStatus status;

  const PracticeSession({
    required this.id,
    required this.routineId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.status,
  });

  @override
  List<Object?> get props => [id, routineId, startTime, endTime, durationMinutes, status];
}

/// Status of a practice session.
enum SessionStatus {
  completed,
  skipped,
  inProgress,
  interrupted,
}
