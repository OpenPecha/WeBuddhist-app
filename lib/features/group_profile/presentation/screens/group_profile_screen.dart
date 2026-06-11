import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_body.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupProfileScreen extends ConsumerWidget {
  final String groupId;

  const GroupProfileScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(groupProfileProvider(groupId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: profileAsync.when(
                data: (either) {
                  return either.fold(
                    (failure) => Center(
                      child: ErrorStateWidget(
                        error: failure,
                        onRetry:
                            () => ref.invalidate(groupProfileProvider(groupId)),
                      ),
                    ),
                    (profile) =>
                        GroupProfileBody(profile: profile, isDark: isDark),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => Center(
                      child: ErrorStateWidget(
                        error: error,
                        onRetry:
                            () => ref.invalidate(groupProfileProvider(groupId)),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MainNavigationBottomBar(
        onTabChanged: (_) => context.go('/home'),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }
}
