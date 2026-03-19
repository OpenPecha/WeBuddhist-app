import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';
import 'package:flutter_pecha/features/plans/domain/entities/week_plan.dart';

/// Plan entity for meditation practice plans.
class Plan extends BaseEntity {
  final String id;
  final String title;
  final String? titleTibetan;
  final String description;
  final String authorId;
  final String? authorName;
  final String? coverImageUrl;
  final int totalDays;
  final DifficultyLevel difficulty;
  final List<String> tags;
  final List<WeekPlan> weekPlans;

  const Plan({
    required this.id,
    required this.title,
    this.titleTibetan,
    required this.description,
    required this.authorId,
    this.authorName,
    this.coverImageUrl,
    required this.totalDays,
    required this.difficulty,
    this.tags = const [],
    this.weekPlans = const [],
  });

  /// Get display title based on language preference.
  String getDisplayTitle(bool preferTibetan) {
    if (preferTibetan && titleTibetan != null && titleTibetan!.isNotEmpty) {
      return titleTibetan!;
    }
    return title;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    titleTibetan,
    description,
    authorId,
    authorName,
    coverImageUrl,
    totalDays,
    difficulty,
    tags,
    weekPlans,
  ];
}

/// Difficulty level of a plan.
enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  allLevels,
}
