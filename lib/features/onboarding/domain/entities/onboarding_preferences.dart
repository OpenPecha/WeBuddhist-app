import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// A hardcoded event shown on the onboarding event page.
class OnboardingEventPlan {
  final String planId;
  final String eventLabel;
  final String planName;
  final String description;
  final int totalDays;

  const OnboardingEventPlan({
    required this.planId,
    required this.eventLabel,
    required this.planName,
    required this.description,
    required this.totalDays,
  });
}

/// All events shown on the onboarding event selection page.
/// Add more entries here as new events are launched.
const kOnboardingEvents = <OnboardingEventPlan>[
  OnboardingEventPlan(
    planId: 'b42c9270-8bc9-4a98-b375-924a948ab18e',
    eventLabel: 'ITCC Bodhgaya · Dec 2026',
    planName: 'Abhidhamma in a Year',
    description: '200 days prep for the International Tipitaka Chanting Ceremony',
    totalDays: 8,
  ),
];

/// Onboarding preferences entity.
class OnboardingPreferences extends BaseEntity {
  final String userId;
  final List<String> interests;
  final String primaryLanguage;
  final int dailyPracticeGoalMinutes;
  final List<String> preferredPracticeTypes;
  final DateTime completedAt;
  final List<String> selectedPaths;

  /// Plan IDs the user opted into from the onboarding event page.
  /// Empty when the user skipped or unchecked all events.
  final List<String> enrolledEventPlanIds;

  const OnboardingPreferences({
    required this.userId,
    this.interests = const [],
    this.primaryLanguage = 'en',
    this.dailyPracticeGoalMinutes = 30,
    this.preferredPracticeTypes = const [],
    required this.completedAt,
    this.selectedPaths = const [],
    this.enrolledEventPlanIds = const [],
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
    List<String>? enrolledEventPlanIds,
  }) {
    return OnboardingPreferences(
      userId: userId ?? this.userId,
      interests: interests ?? this.interests,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      dailyPracticeGoalMinutes: dailyPracticeGoalMinutes ?? this.dailyPracticeGoalMinutes,
      preferredPracticeTypes: preferredPracticeTypes ?? this.preferredPracticeTypes,
      completedAt: completedAt ?? this.completedAt,
      selectedPaths: selectedPaths ?? this.selectedPaths,
      enrolledEventPlanIds: enrolledEventPlanIds ?? this.enrolledEventPlanIds,
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
    enrolledEventPlanIds,
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
  static const String ambedkarBuddhism = 'ambedkar_buddhism';
}
