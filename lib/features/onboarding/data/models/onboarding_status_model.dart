/// API model for GET/PUT /users/me/onboarding.
class OnboardingStatusModel {
  const OnboardingStatusModel({required this.hasSeenOnboarding});

  final bool hasSeenOnboarding;

  factory OnboardingStatusModel.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusModel(
      hasSeenOnboarding: json['has_seen_onboarding'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'has_seen_onboarding': hasSeenOnboarding,
      };
}
