import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/connect/domain/entities/discover_groups_page.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_header.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/discover_group_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/discover_groups_section.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/my_groups_section_skeleton.dart';
import 'package:flutter_pecha/features/connect/presentation/screens/group_search_screen.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/shared/widgets/main_tab_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
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
    final joinedGroupIds = displayedMyGroups.map((group) => group.id).toSet();
    final displayedDiscoverGroups = filterDiscoverGroups(
      discoverGroups: discoverState.groups,
      joinedGroupIds: joinedGroupIds,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: MainTabAppBar(
        title: context.l10n.nav_connect,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GroupSearchScreen(),
                ),
              );
            },
            icon: Icon(
              AppAssets.exploreUnselected,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: context.l10n.text_search,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            ..._buildDiscoverGroupsSlivers(
              discoverState,
              displayedDiscoverGroups,
            ),
            ..._buildMyGroupsSlivers(
              context,
              myGroupsAsync,
              displayedMyGroups,
              isDark,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDiscoverGroupsSlivers(
    DiscoverGroupsState discoverState,
    List<GroupProfile> groups,
  ) {
    if (groups.isNotEmpty) {
      return [
        const SliverToBoxAdapter(child: ConnectHeader()),
        SliverToBoxAdapter(
          child: DiscoverGroupsSection(
            groups: groups,
            total: groups.length,
          ),
        ),
      ];
    }

    if (discoverState.isLoading && discoverState.groups.isEmpty) {
      return const [
        SliverToBoxAdapter(child: ConnectHeader()),
        SliverToBoxAdapter(child: MyGroupsSectionSkeleton()),
      ];
    }

    return const [];
  }

  List<Widget> _buildMyGroupsSlivers(
    BuildContext context,
    AsyncValue<DiscoverGroupsPage> myGroupsAsync,
    List<GroupProfile> displayedMyGroups,
    bool isDark,
  ) {
    if (myGroupsAsync.isLoading && displayedMyGroups.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }

    if (displayedMyGroups.isEmpty) {
      return [_buildStaticConnectImage()];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        sliver: SliverToBoxAdapter(
          child: Text(
            context.l10n.my_groups,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        sliver: SliverList.separated(
          itemCount: displayedMyGroups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return DiscoverGroupCard(
              group: displayedMyGroups[index],
              showJoinButton: false,
            );
          },
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
}
