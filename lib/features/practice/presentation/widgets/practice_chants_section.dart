import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_explore_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/all_recitations_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_chant_list_tile.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_container.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_skeleton.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PracticeChantsSection extends ConsumerWidget {
  const PracticeChantsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final recitationsAsync = ref.watch(practiceExploreRecitationsProvider);

    return recitationsAsync.when(
      data: (either) => either.fold(
        (_) => const SizedBox.shrink(),
        (recitations) {
          if (recitations.isEmpty) return const SizedBox.shrink();
          final preview = recitations.take(2).toList();
          return PracticeSectionContainer(
            title: l10n.home_chants,
            seeAllLabel: recitations.length > 2 ? l10n.see_all : null,
            onSeeAll: recitations.length > 2
                ? () => _showAllRecitations(context, recitations)
                : null,
            child: Column(
              children: preview
                  .map((r) => PracticeChantListTile(
                        recitation: r,
                        onTap: () => _navigateToRecitation(context, r),
                      ))
                  .toList(),
            ),
          );
        },
      ),
      loading: () => const PracticeSectionSkeleton(height: 120),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _navigateToRecitation(BuildContext context, RecitationModel recitation) {
    final navigationContext = NavigationContext(
      source: NavigationSource.normal,
    );
    context.push('/reader/${recitation.textId}', extra: navigationContext);
  }

  void _showAllRecitations(
    BuildContext context,
    List<RecitationModel> recitations,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllRecitationsScreen(
          recitations: recitations,
          onTap: (r) => _navigateToRecitation(context, r),
        ),
      ),
    );
  }
}
