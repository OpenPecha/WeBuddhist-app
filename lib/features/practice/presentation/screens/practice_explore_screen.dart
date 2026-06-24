import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_explore_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_accumulations_section.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_chants_section.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_plans_section.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_tab_button.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_timers_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PracticeExploreScreen extends ConsumerStatefulWidget {
  const PracticeExploreScreen({super.key});

  @override
  ConsumerState<PracticeExploreScreen> createState() =>
      _PracticeExploreScreenState();
}

class _PracticeExploreScreenState extends ConsumerState<PracticeExploreScreen> {
  Future<void> _refreshAll() async {
    ref.invalidate(practiceExploreSeriesProvider);
    ref.invalidate(practiceExploreRecitationsProvider);
    ref.invalidate(practiceExploreAccumulatorsProvider);
    ref.invalidate(practiceExploreTimersProvider);
    await Future.wait([
      ref.read(practiceExploreSeriesProvider.future),
      ref.read(practiceExploreRecitationsProvider.future),
      ref.read(practiceExploreAccumulatorsProvider.future),
      ref.read(practiceExploreTimersProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                l10n.nav_practice,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionButtons(context),
            const SizedBox(height: 4),
            Expanded(child: _buildExploreContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: PracticeTabButton(
              label: l10n.routine_title,
              variant: PracticeActionButtonVariant.filled,
              onTap: () => context.pushNamed('my-practices'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PracticeTabButton(
              label: l10n.bookmarks,
              icon: Icons.bookmark_border,
              variant: PracticeActionButtonVariant.outlined,
              onTap: () => context.pushNamed('bookmarks'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreContent() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: const CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: PracticePlansSection()),
          SliverToBoxAdapter(child: PracticeChantsSection()),
          SliverToBoxAdapter(child: PracticeAccumulationsSection()),
          SliverToBoxAdapter(child: PracticeTimersSection()),
          SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
