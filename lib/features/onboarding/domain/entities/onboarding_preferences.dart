import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Onboarding preferences entity.
class OnboardingPreferences extends BaseEntity {
  final String userId;
  final List<String> interests;
  final String primaryLanguage;
  final int dailyPracticeGoalMinutes;
  final List<String> preferredPracticeTypes;
  final DateTime completedAt;

  const OnboardingPreferences({
    required this.userId,
    this.interests = const [],
    this.primaryLanguage = 'en',
    this.dailyPracticeGoalMinutes = 30,
    this.preferredPracticeTypes = const [],
    required this.completedAt,
  });

  /// Creates a copy with the specified fields replaced with new values
  OnboardingPreferences copyWith({
    String? userId,
    List<String>? interests,
    String? primaryLanguage,
    int? dailyPracticeGoalMinutes,
    List<String>? preferredPracticeTypes,
    DateTime? completedAt,
  }) {
    return OnboardingPreferences(
      userId: userId ?? this.userId,
      interests: interests ?? this.interests,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      dailyPracticeGoalMinutes: dailyPracticeGoalMinutes ?? this.dailyPracticeGoalMinutes,
      preferredPracticeTypes: preferredPracticeTypes ?? this.preferredPracticeTypes,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    interests,
    primaryLanguage,
    dailyPracticeGoalMinutes,
    preferredPracticeTypes,
    completedAt,
  ];
}

/// Onboarding step entity.
class OnboardingStep extends Equatable {
  final int stepNumber;
  final String title;
  final String? description;
  final List<OnboardingOption> options;
  final bool isCompleted;

  const OnboardingStep({
    required this.stepNumber,
    required this.title,
    this.description,
    this.options = const [],
    this.isCompleted = false,
  });

  @override
  List<Object?> get props => [stepNumber, title, description, options, isCompleted];
}

/// Onboarding option entity.
class OnboardingOption extends Equatable {
  final String value;
  final String label;
  final String? iconPath;
  final bool isSelected;

  const OnboardingOption({
    required this.value,
    required this.label,
    this.iconPath,
    this.isSelected = false,
  });

  @override
  List<Object?> get props => [value, label, iconPath, isSelected];
}
