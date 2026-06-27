import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// First onboarding screen: "Welcome to WeBuddhist"
/// Based on Figma design node-id=127-147
class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildTitle(context),
                    const Spacer(),
                    _buildLogoSection(size),
                    const SizedBox(height: 24),
                    _buildTagline(context),
                    const Spacer(),
                    _buildCTAButton(context),
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

  Widget _buildTitle(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Text(
          context.l10n.onboarding_welcome,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        Text(
          context.l10n.appTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            fontFamily: getFontFamily('en'),
            color: onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.onboarding_setup_subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  Widget _buildTagline(BuildContext context) {
    return Text(
      context.l10n.onboarding_tagline,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildLogoSection(Size size) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: Image.asset(
            'assets/images/webuddhist_gold.png',
            width: 200,
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              // Fallback icon if logo is not found
              return const Icon(
                Icons.self_improvement_rounded,
                size: 48,
                color: AppColors.brandblue,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCTAButton(BuildContext context) {
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
          context.l10n.onboarding_find_peace,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
