import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_header.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/discover_group_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  static const _heroImagePath =
      'assets/images/tag_cover/ultimate_reality.png';

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

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(discoverGroupsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(discoverGroupsProvider.notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: ConnectHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.asset(
                        _heroImagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
              ..._buildGroupsSlivers(context, groupsState, isDark),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupsSlivers(
    BuildContext context,
    DiscoverGroupsState groupsState,
    bool isDark,
  ) {
    if (groupsState.isLoading && groupsState.groups.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (groupsState.error != null && groupsState.groups.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorStateWidget(
            error: groupsState.error!,
            onRetry: () => ref.read(discoverGroupsProvider.notifier).retry(),
            customMessage: context.l10n.connect_groups_load_error,
          ),
        ),
      ];
    }

    if (groupsState.groups.isEmpty && !groupsState.isLoading) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(isDark: isDark),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        sliver: SliverList.separated(
          itemCount:
              groupsState.groups.length + (groupsState.hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == groupsState.groups.length) {
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

            return DiscoverGroupCard(group: groupsState.groups[index]);
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppAssets.connectUnselected,
            size: 48,
            color: subtitleColor,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.connect_groups_empty_title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.connect_groups_empty_subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
