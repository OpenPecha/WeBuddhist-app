import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/presentation/providers/timers_providers.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/preset_timer_card.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/timer_more_bottom_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
            _buildAppBar(context, l10n.meditation_timer),
            Expanded(
              child: timersAsync.when(
                data: (timersEither) {
                  return timersEither.fold(
                    (failure) => ErrorStateWidget(
                      error: failure,
                      onRetry: () => _refreshPresetTimers(ref),
                    ),
                    (timers) {
                      if (timers.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () => _refreshPresetTimers(ref),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.55,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Text(
                                      l10n.no_feature_content,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => _refreshPresetTimers(ref),
                        child: _PresetTimersGrid(
                          timers: _sortedPresetTimers(timers),
                          minLabel: l10n.timer_min,
                        ),
                      );
                    },
                  );
                },
                loading: () => const _PresetTimersGridSkeleton(),
                error:
                    (error, _) => ErrorStateWidget(
                      error: error,
                      onRetry: () => _refreshPresetTimers(ref),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshPresetTimers(WidgetRef ref) async {
    await ref.read(timersDomainRepositoryProvider).refreshPresetTimers();
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
  const _PresetTimersGrid({required this.timers, required this.minLabel});

  final List<PresetTimer> timers;
  final String minLabel;

  void _openMoreSheet(BuildContext context, PresetTimer timer) {
    showTimerMoreBottomSheet(
      context,
      timer: timer,
      onAddToPractices:
          () => context.push(
            AppRoutes.practiceEditRoutine,
            extra: {'initialTimer': timer},
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PresetTimersScreen._horizontalPadding),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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
            onTap: () => context.push('/home/timers/active', extra: timer),
            onMoreTap: () => _openMoreSheet(context, timer),
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
      child: Skeletonizer(
        enabled: true,
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
            return Material(
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE4E4E4)),
              ),
              clipBehavior: Clip.antiAlias,
              child: const AspectRatio(
                aspectRatio: 1,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Bone(width: 56, height: 58),
                        SizedBox(height: 8),
                        Bone(width: 36, height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
