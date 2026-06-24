import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_explore_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_container.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_skeleton.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_timer_card.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PracticeTimersSection extends ConsumerWidget {
  const PracticeTimersSection({super.key});

  static const _previewCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final timersAsync = ref.watch(practiceExploreTimersProvider);

    return timersAsync.when(
      data:
          (either) => either.fold((_) => const SizedBox.shrink(), (timers) {
            if (timers.isEmpty) return const SizedBox.shrink();
            final preview = timers.take(_previewCount).toList();
            return PracticeSectionContainer(
              title: l10n.meditation_timer,
              seeAllLabel:
                  timers.length > _previewCount ? l10n.see_all : null,
              onSeeAll:
                  timers.length > _previewCount
                      ? () => context.pushNamed('home-timers')
                      : null,
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: preview.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final timer = preview[index];
                    return SizedBox(
                      width: 150,
                      height: 100,
                      child: PracticeTimerCard(
                        timer: timer,
                        minLabel: l10n.timer_min,
                        onTap: () => _navigateToTimer(context, ref, timer),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
      loading: () => const PracticeSectionSkeleton(height: 100),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _navigateToTimer(
    BuildContext context,
    WidgetRef ref,
    PresetTimer timer,
  ) {
    final isGuest = ref.read(authProvider).isGuest;
    if (isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }
    context.push('/home/timers/active', extra: timer);
  }
}
