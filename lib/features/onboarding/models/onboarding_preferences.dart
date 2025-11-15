/// Model for storing user preferences collected during onboarding
class OnboardingPreferences {
  const OnboardingPreferences({this.preferredLanguage, this.selectedPaths});

  final String? preferredLanguage;
  final List<String>? selectedPaths;

  /// Creates a copy with the specified fields replaced with new values
  OnboardingPreferences copyWith({
    String? preferredLanguage,
    List<String>? selectedPaths,
  }) {
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
    return preferredLanguage != null &&
        selectedPaths != null &&
        selectedPaths!.isNotEmpty;
  }

  @override
  String toString() {
    return 'OnboardingPreferences( '
        'preferredLanguage: $preferredLanguage, '
        'selectedPaths: $selectedPaths)';
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
