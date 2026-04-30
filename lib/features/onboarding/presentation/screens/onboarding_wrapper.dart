import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/route_config.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_1.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_3.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_4.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_5.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_screen_event.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Wrapper for onboarding screens with Riverpod state management.
/// Page order:
///   0 – Welcome
///   1 – Language
///   2 – Tradition
///   3 – Events (new)
///   4 – Finish / "Begin Your Practice"
class OnboardingWrapper extends ConsumerStatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    ref.read(onboardingProvider.notifier).goToNextPage();
  }

  void _previousPage() {
    ref.read(onboardingProvider.notifier).goToPreviousPage();
  }

  Future<void> _completeOnboarding() async {
    final completed =
        await ref.read(onboardingProvider.notifier).submitPreferences();
    if (!mounted || !completed) return;

    // Grab enrolled plans before navigating away (state will be invalidated).
    final enrolledPlans =
        List<UserPlansModel>.from(ref.read(onboardingProvider).enrolledPlans);

    // If the user enrolled in events, store the first plan as a pending
    // navigation target. HomeScreen will pick this up after the notification-
    // permission flow completes, then switch to the Practice tab and open the
    // plan detail. This ensures the system notification dialog is shown first.
    if (enrolledPlans.isNotEmpty) {
      ref.read(pendingOnboardingPlanProvider.notifier).state =
          enrolledPlans.first;
    }

    if (mounted) context.go(RouteConfig.home);
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(
      onboardingProvider.select((state) => state.currentPage),
    );

    ref.listen<int>(
      onboardingProvider.select((state) => state.currentPage),
      (previous, next) {
        if (_pageController.hasClients && previous != next) {
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
    );

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (int page) {
              if (page != currentPage) {
                if (page > currentPage) {
                  ref.read(onboardingProvider.notifier).goToNextPage();
                } else {
                  ref.read(onboardingProvider.notifier).goToPreviousPage();
                }
              }
            },
            children: [
              OnboardingScreen1(onNext: _nextPage),
              OnboardingScreen3(onNext: _nextPage, onBack: _previousPage),
              OnboardingScreen4(onNext: _nextPage, onBack: _previousPage),
              OnboardingScreenEvent(onNext: _nextPage, onBack: _previousPage),
              OnboardingScreen5(onComplete: _completeOnboarding),
            ],
          ),
        ],
      ),
    );
  }
}
