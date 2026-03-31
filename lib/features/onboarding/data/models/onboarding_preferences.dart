import '../../domain/entities/onboarding_preferences.dart' as domain;

/// Model for storing user preferences collected during onboarding
///
/// This handles conversion between JSON and the OnboardingPreferences domain entity.
class OnboardingPreferences {
  const OnboardingPreferences({this.preferredLanguage});

  final String? preferredLanguage;

  /// Creates a copy with the specified fields replaced with new values
  OnboardingPreferences copyWith({String? preferredLanguage}) {
    return OnboardingPreferences(
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {'preferredLanguage': preferredLanguage};
  }

  /// Creates from JSON
  factory OnboardingPreferences.fromJson(Map<String, dynamic> json) {
    return OnboardingPreferences(
      preferredLanguage: json['preferredLanguage'] as String?,
    );
  }

  /// Checks if all preferences are complete
  bool get isComplete {
    return preferredLanguage != null;
  }

  /// Convert to OnboardingPreferences domain entity.
  ///
  /// Note: This model only stores preferredLanguage, so other fields
  /// use default values. The full domain entity has more comprehensive fields.
  domain.OnboardingPreferences toEntity({
    required String userId,
    List<String> interests = const [],
    int dailyPracticeGoalMinutes = 30,
    List<String> preferredPracticeTypes = const [],
    DateTime? completedAt,
  }) {
    return domain.OnboardingPreferences(
      userId: userId,
      interests: interests,
      primaryLanguage: preferredLanguage ?? 'en',
      dailyPracticeGoalMinutes: dailyPracticeGoalMinutes,
      preferredPracticeTypes: preferredPracticeTypes,
      completedAt: completedAt ?? DateTime.now(),
    );
  }

  /// Create OnboardingPreferences from a domain entity.
  factory OnboardingPreferences.fromEntity(domain.OnboardingPreferences entity) {
    return OnboardingPreferences(
      preferredLanguage: entity.primaryLanguage,
    );
  }

  @override
  String toString() {
    return 'OnboardingPreferences(preferredLanguage: $preferredLanguage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingPreferences &&
        other.preferredLanguage == preferredLanguage;
  }

  @override
  int get hashCode {
    return preferredLanguage?.hashCode ?? 0;
  }
}

/// Language options
class PreferredLanguage {
  static const String tibetan = 'tibetan';
  static const String english = 'english';
  static const String chinese = 'chinese';
}
