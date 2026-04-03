import '../../domain/entities/onboarding_preferences.dart' as domain;

// Re-export constants for backward compatibility with existing imports
export '../../domain/entities/onboarding_preferences.dart' show PreferredLanguage, BuddhistPath;

/// Model for storing user preferences collected during onboarding
///
/// This handles conversion between JSON and the OnboardingPreferences domain entity.
class OnboardingPreferences {
  const OnboardingPreferences({this.preferredLanguage, this.selectedPaths});

  final String? preferredLanguage;
  final List<String>? selectedPaths;

  /// Creates a copy with the specified fields replaced with new values
  OnboardingPreferences copyWith({String? preferredLanguage, List<String>? selectedPaths}) {
    return OnboardingPreferences(
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      selectedPaths: selectedPaths ?? this.selectedPaths,
    );
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'preferredLanguage': preferredLanguage,
      'selectedPaths': selectedPaths,
    };
  }

  /// Creates from JSON
  factory OnboardingPreferences.fromJson(Map<String, dynamic> json) {
    return OnboardingPreferences(
      preferredLanguage: json['preferredLanguage'] as String?,
      selectedPaths:
          (json['selectedPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
    );
  }

  /// Checks if all preferences are complete
  bool get isComplete {
    return preferredLanguage != null;
  }

  /// Convert to OnboardingPreferences domain entity.
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
      selectedPaths: selectedPaths ?? [],
    );
  }

  /// Create OnboardingPreferences from a domain entity.
  factory OnboardingPreferences.fromEntity(domain.OnboardingPreferences entity) {
    return OnboardingPreferences(
      preferredLanguage: entity.primaryLanguage,
      selectedPaths: entity.selectedPaths,
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
        other.preferredLanguage == preferredLanguage &&
        _listEquals(other.selectedPaths, selectedPaths);
  }

  @override
  int get hashCode {
    return Object.hash(preferredLanguage, selectedPaths);
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
