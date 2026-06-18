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
  final String language;

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
    this.language = 'en',
  });

  /// Get display title based on language preference.
  String getDisplayTitle(bool preferTibetan) {
    if (preferTibetan && titleTibetan != null && titleTibetan!.isNotEmpty) {
      return titleTibetan!;
    }
    return title;
  }

  /// Creates a copy with the specified fields replaced with new values
  Plan copyWith({
    String? id,
    String? title,
    String? titleTibetan,
    String? description,
    String? authorId,
    String? authorName,
    String? coverImageUrl,
    int? totalDays,
    DifficultyLevel? difficulty,
    List<String>? tags,
    List<WeekPlan>? weekPlans,
    String? language,
  }) {
    return Plan(
      id: id ?? this.id,
      title: title ?? this.title,
      titleTibetan: titleTibetan ?? this.titleTibetan,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      totalDays: totalDays ?? this.totalDays,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      weekPlans: weekPlans ?? this.weekPlans,
      language: language ?? this.language,
    );
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
    language,
  ];
}

/// Difficulty level of a plan.
enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  allLevels,
}
