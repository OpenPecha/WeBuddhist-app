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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Title: "Welcome to WeBuddhist"
              _buildTitle(context),
              const Spacer(),
              // Center logo with concentric circles
              _buildLogoSection(size),
              const Spacer(),
              // Quote text
              _buildQuote(context),
              const SizedBox(height: 32),
              // CTA Button
              _buildCTAButton(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.onboarding_welcome,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
        ),
        Text(
          context.l10n.appTitle,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            fontFamily: getFontFamily('en'),
          ),
        ),
      ],
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
                color: AppColors.primary,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuote(BuildContext context) {
    return Column(
      children: [
        Text(
          "\"${context.l10n.onboarding_quote}\"",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: getFontFamily('en'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "— Dhammapada 122",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: getFontFamily('en'),
          ),
        ),
      ],
    );
  }

  Widget _buildCTAButton(BuildContext context) {
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
        child: Text(
          context.l10n.onboarding_find_peace,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.306,
          ),
        ),
      ),
    );
  }
}
