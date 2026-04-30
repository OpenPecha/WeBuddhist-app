import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:flutter_pecha/features/onboarding/domain/entities/onboarding_preferences.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/event_enrollment_providers.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_back_button.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_question_title.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Onboarding event page: lets the user opt into upcoming Buddhist events.
/// Each event maps to a plan that gets auto-enrolled with a 9:00 AM time block.
class OnboardingScreenEvent extends ConsumerStatefulWidget {
  const OnboardingScreenEvent({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<OnboardingScreenEvent> createState() =>
      _OnboardingScreenEventState();
}

class _OnboardingScreenEventState extends ConsumerState<OnboardingScreenEvent> {
  /// Plan IDs currently checked by the user. All events are checked by default.
  late Set<String> _checkedPlanIds;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkedPlanIds = {for (final e in kOnboardingEvents) e.planId};
  }

  void _toggleEvent(String planId) {
    setState(() {
      if (_checkedPlanIds.contains(planId)) {
        _checkedPlanIds.remove(planId);
      } else {
        _checkedPlanIds.add(planId);
      }
      _errorMessage = null;
    });
  }

  Future<void> _handleContinue() async {
    if (_isLoading) return;

    // If nothing selected, just advance — enrollment is optional.
    if (_checkedPlanIds.isEmpty) {
      widget.onNext();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(eventEnrollmentServiceProvider);
      final enrolledPlans = await service.enrollInEvents(_checkedPlanIds.toList());

      await ref.read(onboardingProvider.notifier).setEnrolledPlans(enrolledPlans);

      if (mounted) widget.onNext();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not enroll. Please check your connection and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              OnboardingBackButton(onBack: widget.onBack),
              const SizedBox(height: 40),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OnboardingQuestionTitle(
                        title: 'Join an\nupcoming event?',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Optional · Uncheck to skip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.2,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 36),
                      ...kOnboardingEvents.map(
                        (event) => _EventCard(
                          event: event,
                          isSelected: _checkedPlanIds.contains(event.planId),
                          isDark: isDark,
                          onTap: () => _toggleEvent(event.planId),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ReminderNote(isDark: isDark),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Center(child: _ContinueButton(
                        isLoading: _isLoading,
                        onPressed: _handleContinue,
                      )),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Private widgets ───

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final OnboardingEventPlan event;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.greyMedium : const Color(0xFFE0E0E0));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1.5,
            ),
            color: isSelected
                ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06)
                : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.eventLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Plan name
                    Text(
                      event.planName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Description + duration
                    Text(
                      '${event.description} · ${event.totalDays} days',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Checkbox(isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.greyMedium,
          width: 2,
        ),
        color: isSelected ? AppColors.primary : Colors.transparent,
      ),
      child: isSelected
          ? const Center(
              child: Icon(Icons.check, size: 14, color: Colors.white),
            )
          : null,
    );
  }
}

class _ReminderNote extends StatelessWidget {
  const _ReminderNote({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.notifications_outlined,
          size: 16,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Selected events will be added to your practice with a 9:00 AM daily reminder.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.isLoading, required this.onPressed});
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.6,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.306,
                ),
              ),
      ),
    );
  }
}
