import 'package:flutter_pecha/features/onboarding/domain/entities/onboarding_preferences.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';

/// State for onboarding flow management
class OnboardingState {
  const OnboardingState({
    required this.preferences,
    required this.currentPage,
    required this.isLoading,
    this.error,
    this.enrolledPlans = const [],
  });

  final OnboardingPreferences preferences;
  final int currentPage;
  final bool isLoading;
  final String? error;

  /// Plans enrolled from the event page. Transient — used only for post-onboarding
  /// navigation to the plan detail screen. Not persisted beyond this session.
  final List<UserPlansModel> enrolledPlans;

  /// Initial state
  factory OnboardingState.initial() {
    return OnboardingState(
      preferences: OnboardingPreferences(
        userId: '',
        completedAt: DateTime.now(),
      ),
      currentPage: 0,
      isLoading: false,
    );
  }

  /// Loading state
  OnboardingState copyWithLoading(bool loading) {
    return OnboardingState(
      preferences: preferences,
      currentPage: currentPage,
      isLoading: loading,
      error: error,
      enrolledPlans: enrolledPlans,
    );
  }

  /// Success state with updated preferences
  OnboardingState copyWithPreferences(OnboardingPreferences newPreferences) {
    return OnboardingState(
      preferences: newPreferences,
      currentPage: currentPage,
      isLoading: false,
      error: null,
      enrolledPlans: enrolledPlans,
    );
  }

  /// Error state
  OnboardingState copyWithError(String errorMessage) {
    return OnboardingState(
      preferences: preferences,
      currentPage: currentPage,
      isLoading: false,
      error: errorMessage,
      enrolledPlans: enrolledPlans,
    );
  }

  /// Update current page
  OnboardingState copyWithPage(int page) {
    return OnboardingState(
      preferences: preferences,
      currentPage: page,
      isLoading: isLoading,
      error: error,
      enrolledPlans: enrolledPlans,
    );
  }

  /// General copy with method
  OnboardingState copyWith({
    OnboardingPreferences? preferences,
    int? currentPage,
    bool? isLoading,
    String? error,
    List<UserPlansModel>? enrolledPlans,
  }) {
    return OnboardingState(
      preferences: preferences ?? this.preferences,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      enrolledPlans: enrolledPlans ?? this.enrolledPlans,
    );
  }

  @override
  String toString() {
    return 'OnboardingState(preferences: $preferences, currentPage: $currentPage, isLoading: $isLoading, error: $error)';
  }
}
