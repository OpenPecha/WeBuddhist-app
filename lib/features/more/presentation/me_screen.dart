import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/features/more/presentation/providers/user_stats_provider.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/me_profile_header.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/me_stats_section.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/me_stats_section_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            localizations.nav_me,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        actions: [
          IconButton(
            icon: Icon(
              AppAssets.settings,
              size: 24,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => context.push('/home/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child:
            (authState.isLoggedIn && !authState.isGuest)
                ? const _LoggedInProfile()
                : const _GuestView(),
      ),
    );
  }
}

class _LoggedInProfile extends ConsumerStatefulWidget {
  const _LoggedInProfile();

  @override
  ConsumerState<_LoggedInProfile> createState() => _LoggedInProfileState();
}

class _LoggedInProfileState extends ConsumerState<_LoggedInProfile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshStats();
    });
  }

  Future<void> _refreshStats() async {
    ref.read(cacheInterceptorProvider).invalidate('/users/me/stats');
    ref.invalidate(userStatsFutureProvider);
    await ref.read(userStatsFutureProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).user;
    final statsAsync = ref.watch(userStatsFutureProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = statsAsync.maybeWhen(
      data: (either) => either.fold((_) => UserStats.empty, (stats) => stats),
      orElse: () => UserStats.empty,
    );

    return RefreshIndicator(
      onRefresh: _refreshStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MeProfileHeader(user: user),
            if (statsAsync.isLoading)
              const MeStatsSectionSkeleton()
            else
              MeStatsSection(stats: stats),
          ],
        ),
      ),
    );
  }
}

class _GuestView extends ConsumerWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIOS = Platform.isIOS;

    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.grey300,
              child: Icon(
                AppAssets.profile,
                size: 44,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.me_guest_headline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 34,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              localizations.me_guest_subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: 40),
            if (authState.isLoading)
              const SizedBox(
                height: 52,
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _SocialButton(
                onTap: () => authNotifier.login(connection: 'google'),
                backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                foregroundColor: isDark ? Colors.white : Colors.black87,
                borderColor:
                    isDark ? AppColors.cardBorderDark : AppColors.grey300,
                label: localizations.continueWithGoogle,
                icon: Image.asset(AppAssets.googleIcon, width: 23, height: 23),
              ),
              if (isIOS) ...[
                const SizedBox(height: 14),
                _SocialButton(
                  onTap: () => authNotifier.login(connection: 'apple'),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  borderColor: Colors.transparent,
                  label: localizations.continueWithApple,
                  icon: const Icon(
                    AppAssets.apple,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.label,
    required this.icon,
  });

  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
