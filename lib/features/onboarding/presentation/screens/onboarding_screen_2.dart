import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_back_button.dart';

/// Second onboarding screen: "Next, here's how it works."
class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = onSurface.withValues(alpha: 0.65);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    OnboardingBackButton(onBack: onBack),
                    const SizedBox(height: 40),
                    Text(
                      l10n.onboarding_2_title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.onboarding_2_subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _OnboardingStepItem(
                      number: '1',
                      title: l10n.onboarding_2_step1_title,
                      description: l10n.onboarding_2_step1_desc,
                    ),
                    const SizedBox(height: 32),
                    _OnboardingStepItem(
                      number: '2',
                      title: l10n.onboarding_2_step2_title,
                      description: l10n.onboarding_2_step2_desc,
                    ),
                    const SizedBox(height: 32),
                    _OnboardingStepItem(
                      number: '3',
                      title: l10n.onboarding_2_step3_title,
                      description: l10n.onboarding_2_step3_desc,
                    ),
                    const Spacer(),
                    _buildContinueButton(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandblue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          context.l10n.onboarding_continue,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _OnboardingStepItem extends StatelessWidget {
  const _OnboardingStepItem({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final descriptionColor = onSurface.withValues(alpha: 0.65);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: onSurface,
            height: 1.2,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: descriptionColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
