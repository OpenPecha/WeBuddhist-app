import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';
import 'package:flutter_pecha/features/plans/domain/entities/week_plan.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

/// Plan entity for meditation practice plans.
class Plan extends BaseEntity {
  final String id;
  final String title;
  final String? titleTibetan;
  final String description;
  final String authorId;
  final String? authorName;
  final ResponsiveImage? coverImage;
  final int totalDays;
  final DifficultyLevel difficulty;
  final List<String> tags;
  final List<WeekPlan> weekPlans;
  final String language;
  final DateTime? startDate;
  final int? displayOrder;

  const Plan({
    required this.id,
    required this.title,
    this.titleTibetan,
    required this.description,
    required this.authorId,
    this.authorName,
    this.coverImage,
    required this.totalDays,
    required this.difficulty,
    this.tags = const [],
    this.weekPlans = const [],
    this.language = 'en',
    this.startDate,
    this.displayOrder,
  });

  /// Smallest cover URL — notifications and legacy string-only callers.
  String? get coverImageUrl => coverImage?.displayUrl;

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
    ResponsiveImage? coverImage,
    String? coverImageUrl,
    int? totalDays,
    DifficultyLevel? difficulty,
    List<String>? tags,
    List<WeekPlan>? weekPlans,
    String? language,
    DateTime? startDate,
    int? displayOrder,
  }) {
    return Plan(
      id: id ?? this.id,
      title: title ?? this.title,
      titleTibetan: titleTibetan ?? this.titleTibetan,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      coverImage:
          coverImageUrl != null
              ? ResponsiveImage.uniform(coverImageUrl)
              : (coverImage ?? this.coverImage),
      totalDays: totalDays ?? this.totalDays,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      weekPlans: weekPlans ?? this.weekPlans,
      language: language ?? this.language,
      startDate: startDate ?? this.startDate,
      displayOrder: displayOrder ?? this.displayOrder,
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
    coverImage,
    totalDays,
    difficulty,
    tags,
    weekPlans,
    language,
    startDate,
    displayOrder,
  ];
}

/// Difficulty level of a plan.
enum DifficultyLevel { beginner, intermediate, advanced, allLevels }
