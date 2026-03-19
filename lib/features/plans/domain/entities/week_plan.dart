import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan_day.dart';

/// Week plan entity representing a week's worth of practice.
class WeekPlan extends Equatable {
  final int weekNumber;
  final String title;
  final String? description;
  final List<PlanDay> days;
  final WeekPlanType type;

  const WeekPlan({
    required this.weekNumber,
    required this.title,
    this.description,
    this.days = const [],
    required this.type,
  });

  @override
  List<Object?> get props => [weekNumber, title, description, days, type];
}

/// Type of week plan.
enum WeekPlanType {
  introduction,
  practice,
  review,
  assessment,
}
