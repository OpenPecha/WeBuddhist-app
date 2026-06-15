import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/presentation/providers/timers_providers.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/preset_timer_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PresetTimersScreen extends ConsumerWidget {
  const PresetTimersScreen({super.key});

  static const _horizontalPadding = 16.0;
  static const _gridSpacing = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final timersAsync = ref.watch(presetTimersFutureProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, l10n.preset_timers),
            Expanded(
              child: timersAsync.when(
                data: (timersEither) {
                  return timersEither.fold(
                    (failure) => ErrorStateWidget(
                      error: failure,
                      onRetry: () => ref.invalidate(presetTimersFutureProvider),
                    ),
                    (timers) {
                      if (timers.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              l10n.no_feature_content,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return _PresetTimersGrid(
                        timers: _sortedPresetTimers(timers),
                        minLabel: l10n.timer_min,
                      );
                    },
                  );
                },
                loading: () => const _PresetTimersGridSkeleton(),
                error:
                    (error, _) => ErrorStateWidget(
                      error: error,
                      onRetry: () => ref.invalidate(presetTimersFutureProvider),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  List<PresetTimer> _sortedPresetTimers(List<PresetTimer> timers) {
    final sorted = List<PresetTimer>.from(timers)
      ..sort((a, b) => a.durationMs.compareTo(b.durationMs));
    return sorted;
  }
}

class _PresetTimersGrid extends StatelessWidget {
  const _PresetTimersGrid({
    required this.timers,
    required this.minLabel,
  });

  final List<PresetTimer> timers;
  final String minLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PresetTimersScreen._horizontalPadding),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: PresetTimersScreen._gridSpacing,
          mainAxisSpacing: PresetTimersScreen._gridSpacing,
          childAspectRatio: 1,
        ),
        itemCount: timers.length,
        itemBuilder: (context, index) {
          final timer = timers[index];
          return PresetTimerCard(
            timer: timer,
            minLabel: minLabel,
          );
        },
      ),
    );
  }
}

class _PresetTimersGridSkeleton extends StatelessWidget {
  const _PresetTimersGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PresetTimersScreen._horizontalPadding),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: PresetTimersScreen._gridSpacing,
          mainAxisSpacing: PresetTimersScreen._gridSpacing,
          childAspectRatio: 1,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }
}
