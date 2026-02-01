import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// First onboarding screen: "Welcome to WeBuddhist"
/// Based on Figma design node-id=127-147
class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Title: "Welcome to WeBuddhist"
              _buildTitle(context),
              const SizedBox(height: 20),
              // Subtitle text
              _buildSubtitle(context),
              const Spacer(),
              // Center logo with concentric circles
              _buildLogoSection(size),
              const Spacer(),
              // Quote text
              _buildQuote(context),
              const SizedBox(height: 32),
              // CTA Button
              _buildCTAButton(theme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    return Text(
      appLocalizations!.onboarding_welcome,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.544,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    return Text(
      appLocalizations!.onboarding_description,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: -0.272,
      ),
    );
  }

  Widget _buildLogoSection(Size size) {
    return Center(
      child: SizedBox(
        width: size.width * 0.7,
        height: size.width * 0.7,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer circle - lightest red
            Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.outerCircleColor,
              ),
            ),
            // Middle circle
            Container(
              width: size.width * 0.52,
              height: size.width * 0.52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.middleCircleColor,
              ),
            ),
            // Inner circle
            Container(
              width: size.width * 0.34,
              height: size.width * 0.34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.innerCircleColor,
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.innerCircleColor,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/webuddhist_logo.png',
                  width: 72,
                  height: 72,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon if logo is not found
                    return const Icon(
                      Icons.self_improvement_rounded,
                      size: 48,
                      color: AppColors.primary,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuote(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        appLocalizations!.onboarding_quote,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.5,
          letterSpacing: -0.272,
          color: theme.colorScheme.onSurface, // Secondary grey from Figma
        ),
      ),
    );
  }

  Widget _buildCTAButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Find your Peace',
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
