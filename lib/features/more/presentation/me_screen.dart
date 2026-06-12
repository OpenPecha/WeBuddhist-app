import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
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
        title: Text(
          localizations.nav_me,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              AppAssets.settings,
              size: 24,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child:
            (authState.isLoggedIn && !authState.isGuest)
                ? _LoggedInProfile(ref: ref)
                : const _GuestView(),
      ),
    );
  }
}

class _LoggedInProfile extends ConsumerWidget {
  const _LoggedInProfile({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final user = widgetRef.watch(userProvider).user;
    final avatarUrl = user?.avatarUrl ?? '';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          // Avatar
          Hero(
            tag: 'profile-avatar',
            child: SizedBox(
              width: 104,
              height: 104,
              child: ClipOval(
                child:
                    avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          // Strip presigned query params so S3 signature rotations
                          // resolve to the same cache entry.
                          cacheKey:
                              Uri.tryParse(
                                avatarUrl,
                              )?.replace(query: '', fragment: '').toString() ??
                              avatarUrl,
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => ColoredBox(
                                color: AppColors.grey300,
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.grey600,
                                    ),
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => ColoredBox(
                                color: AppColors.grey300,
                                child: Center(
                                  child: Icon(
                                    AppAssets.profile,
                                    size: 44,
                                    color: AppColors.grey600,
                                  ),
                                ),
                              ),
                        )
                        : ColoredBox(
                          color: AppColors.grey300,
                          child: Center(
                            child: Icon(
                              AppAssets.profile,
                              size: 44,
                              color: AppColors.grey600,
                            ),
                          ),
                        ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Username
          if (user?.username != null && user!.username!.isNotEmpty)
            Text(
              user.username!,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 8),
          if (user?.aboutMe != null && user!.aboutMe!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                user.aboutMe!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.grey600),
              ),
            ),
        ],
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
