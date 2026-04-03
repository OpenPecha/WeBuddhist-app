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
  final List<String> selectedPaths;

  const OnboardingPreferences({
    required this.userId,
    this.interests = const [],
    this.primaryLanguage = 'en',
    this.dailyPracticeGoalMinutes = 30,
    this.preferredPracticeTypes = const [],
    required this.completedAt,
    this.selectedPaths = const [],
  });

  /// Creates a copy with the specified fields replaced with new values
  OnboardingPreferences copyWith({
    String? userId,
    List<String>? interests,
    String? primaryLanguage,
    int? dailyPracticeGoalMinutes,
    List<String>? preferredPracticeTypes,
    DateTime? completedAt,
    List<String>? selectedPaths,
  }) {
    return OnboardingPreferences(
      userId: userId ?? this.userId,
      interests: interests ?? this.interests,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      dailyPracticeGoalMinutes: dailyPracticeGoalMinutes ?? this.dailyPracticeGoalMinutes,
      preferredPracticeTypes: preferredPracticeTypes ?? this.preferredPracticeTypes,
      completedAt: completedAt ?? this.completedAt,
      selectedPaths: selectedPaths ?? this.selectedPaths,
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
    selectedPaths,
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

/// Language options
class PreferredLanguage {
  static const String tibetan = 'tibetan';
  static const String english = 'english';
  static const String chinese = 'chinese';
}

/// Buddhist path options
class BuddhistPath {
  static const String theravada = 'theravada';
  static const String zen = 'zen';
  static const String tibetanBuddhism = 'tibetan_buddhism';
  static const String pureLand = 'pure_land';
}
