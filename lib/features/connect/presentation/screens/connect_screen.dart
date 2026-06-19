import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/connect/domain/entities/discover_groups_page.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_header.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/discover_group_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/my_groups_section.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/my_groups_section_skeleton.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(discoverGroupsProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.refresh(myGroupsProvider.future),
      ref.read(discoverGroupsProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverGroupsProvider);
    final myGroupsAsync = ref.watch(myGroupsProvider);
    final pendingGroups = ref.watch(pendingJoinedGroupsProvider);
    final pendingUnjoinedIds = ref.watch(pendingUnjoinedGroupIdsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final apiGroups = myGroupsAsync.valueOrNull?.groups ?? const [];
    final displayedMyGroups = mergeMyGroupsWithPending(
      apiGroups: apiGroups,
      pendingGroups: pendingGroups,
      pendingUnjoinedIds: pendingUnjoinedIds,
    );
    final excludedGroupIds = displayedMyGroups.map((g) => g.id).toSet();

    final discoverGroups =
        discoverState.groups
            .where((group) => _shouldShowInDiscover(group, excludedGroupIds))
            .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: ConnectHeader()),
              ..._buildTopSectionSlivers(
                myGroupsAsync,
                displayedMyGroups,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    context.l10n.discover_groups,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              ..._buildDiscoverGroupsSlivers(
                context,
                discoverState,
                discoverGroups,
                isDark,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowInDiscover(GroupProfile group, Set<String> excludedGroupIds) {
    if (excludedGroupIds.contains(group.id)) return false;

    final followState = ref.watch(
      groupFollowProvider(
        GroupFollowKey(groupId: group.id, groupType: group.groupType),
      ),
    );

    return switch (followState) {
      GroupFollowSuccess(isFollowing: true) => false,
      _ => true,
    };
  }

  List<Widget> _buildTopSectionSlivers(
    AsyncValue<DiscoverGroupsPage> myGroupsAsync,
    List<GroupProfile> displayedMyGroups,
  ) {
    if (myGroupsAsync.isLoading && displayedMyGroups.isEmpty) {
      return const [
        SliverToBoxAdapter(child: MyGroupsSectionSkeleton()),
      ];
    }

    if (displayedMyGroups.isEmpty) {
      return [_buildStaticConnectImage()];
    }

    final total = myGroupsAsync.valueOrNull?.total ?? displayedMyGroups.length;

    return [
      SliverToBoxAdapter(
        child: MyGroupsSection(
          groups: displayedMyGroups,
          total: total < displayedMyGroups.length
              ? displayedMyGroups.length
              : total,
        ),
      ),
    ];
  }

  Widget _buildStaticConnectImage() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.asset(AppAssets.connect, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDiscoverGroupsSlivers(
    BuildContext context,
    DiscoverGroupsState groupsState,
    List<GroupProfile> groups,
    bool isDark,
  ) {
    if (groupsState.isLoading && groups.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }

    if (groupsState.error != null && groups.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: ErrorStateWidget(
              error: groupsState.error!,
              onRetry: () => ref.read(discoverGroupsProvider.notifier).retry(),
              customMessage: context.l10n.connect_groups_load_error,
            ),
          ),
        ),
      ];
    }

    if (groups.isEmpty && !groupsState.isLoading) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: _EmptyState(isDark: isDark),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        sliver: SliverList.separated(
          itemCount: groups.length + (groupsState.hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == groups.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child:
                      groupsState.isLoadingMore
                          ? const CircularProgressIndicator()
                          : const SizedBox.shrink(),
                ),
              );
            }

            return DiscoverGroupCard(group: groups[index]);
          },
        ),
      ),
    ];
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(AppAssets.connectUnselected, size: 48, color: subtitleColor),
          const SizedBox(height: 16),
          Text(
            context.l10n.connect_groups_empty_title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.connect_groups_empty_subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: subtitleColor),
          ),
        ],
      ),
    );
  }
}
