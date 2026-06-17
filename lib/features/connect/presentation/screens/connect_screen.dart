import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_header.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/discover_group_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/my_groups_section.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectScreen extends ConsumerWidget {
  const ConnectScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(discoverGroupsProvider);
    ref.invalidate(joinedGroupsProvider);
    await Future.wait([
      ref.read(discoverGroupsProvider.future),
      ref.read(joinedGroupsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final discoverAsync = ref.watch(discoverGroupsProvider);
    final joinedAsync = ref.watch(joinedGroupsProvider);
    final joinedIds = ref.watch(joinedGroupIdsProvider);

    final joinedGroups = joinedAsync.maybeWhen(
      data:
          (either) => either.fold(
            (_) => const <GroupProfile>[],
            (groups) => groups,
          ),
      orElse: () => const <GroupProfile>[],
    );
    final hasJoinedGroups = joinedGroups.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: ConnectHeader()),
              if (!hasJoinedGroups)
                const SliverToBoxAdapter(child: ConnectHeroImage()),
              if (joinedAsync.isLoading && !hasJoinedGroups)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (hasJoinedGroups)
                SliverToBoxAdapter(child: MyGroupsSection(groups: joinedGroups)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, hasJoinedGroups ? 24 : 20, 20, 12),
                  child: Text(
                    l10n.connect_discover_groups,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              discoverAsync.when(
                loading:
                    () => const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (error, _) => SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorStateWidget(
                        error: error,
                        onRetry: () => ref.invalidate(discoverGroupsProvider),
                      ),
                    ),
                data: (either) {
                  return either.fold(
                    (failure) => SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorStateWidget(
                        error: failure,
                        onRetry: () => ref.invalidate(discoverGroupsProvider),
                      ),
                    ),
                    (groups) {
                      final visibleGroups =
                          groups
                              .where((group) => !joinedIds.contains(group.id))
                              .toList();

                      if (visibleGroups.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            child: Text(
                              l10n.connect_no_groups,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList.separated(
                          itemCount: visibleGroups.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final group = visibleGroups[index];
                            return DiscoverGroupCard(
                              group: group,
                              isJoined: joinedIds.contains(group.id),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
