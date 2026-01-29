import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

class ComingSoonScreen extends StatefulWidget {
  const ComingSoonScreen({super.key});

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),

                // Animated logo with breathing effect
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Image.asset(
                      'assets/images/pecha_logo.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // App name
                Text(
                  l10n.pechaHeading,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                Text(
                  l10n.learnLiveShare,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 24),

                // Burgundy divider
                Container(
                  width: 60,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),

                const SizedBox(height: 24),

                // Headline
                Text(
                  l10n.comingSoonHeadline,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
