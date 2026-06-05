import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
              PhosphorIconsRegular.gear,
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
                : _GuestView(
                  onSignIn: () => LoginDrawer.show(context, ref),
                  localizations: localizations,
                ),
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
                                    PhosphorIconsRegular.user,
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
                              PhosphorIconsRegular.user,
                              size: 44,
                              color: AppColors.grey600,
                            ),
                          ),
                        ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          if (user?.fullName != null && user!.fullName.isNotEmpty)
            Text(
              user.fullName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 4),
          // Email
          if (user?.email != null && user!.email!.isNotEmpty)
            Text(
              user.email!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
            ),
          const SizedBox(height: 8),
          // Bio
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

class _GuestView extends StatelessWidget {
  const _GuestView({required this.onSignIn, required this.localizations});

  final VoidCallback onSignIn;
  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
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
                PhosphorIconsRegular.user,
                size: 44,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.profile_guest_title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.profile_guest_subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onSignIn,
              child: Text(localizations.sign_in),
            ),
          ],
        ),
      ),
    );
  }
}
