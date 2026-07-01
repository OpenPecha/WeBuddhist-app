import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/core.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_settings_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mala_beads.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mala_skeleton.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mantra_switcher.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mala_settings_sheet.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MalaScreen extends ConsumerStatefulWidget {
  const MalaScreen({super.key, this.initialPresetId});

  /// Optionally open directly on a specific mantra.
  final String? initialPresetId;

  @override
  ConsumerState<MalaScreen> createState() => _MalaScreenState();
}

class _MalaScreenState extends ConsumerState<MalaScreen> {
  int _index = 0;
  bool _initialisedIndex = false;
  String? _trackedOpenedId;

  void _trackOpened(Mantra mantra) {
    if (_trackedOpenedId == mantra.presetId) return;
    _trackedOpenedId = mantra.presetId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(analyticsServiceProvider)
          .track(
            AnalyticsEvents.malaScreenOpened,
            properties: {'accumulatorId': mantra.presetId},
          );
    });
  }

  void _switch(List<Mantra> mantras, int next) {
    if (next < 0 || next >= mantras.length || next == _index) return;
    final from = mantras[_index].presetId;
    final to = mantras[next].presetId;
    ref
        .read(analyticsServiceProvider)
        .track(
          AnalyticsEvents.malaMantraSwitched,
          properties: {'from': from, 'to': to},
        );
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(malaCatalogueProvider);

    return Scaffold(
      // Clip the page content to its bounds. The bead strand is drawn with an
      // intentional overflow past the arc edges (relied on being clipped); the
      // device-edge clip normally hides it, but during the iOS pop transition
      // the page is composited into a sliding layer where that overflow would
      // otherwise flash onto the incoming screen. This contains it without
      // changing the bead appearance.
      body: ClipRect(
        child: SafeArea(
          child: catalogue.when(
            loading: () => const _MalaAppBarScaffold(child: MalaSkeleton()),
            error:
                (e, _) => _MalaAppBarScaffold(
                  child: _ErrorView(
                    onRetry: () => ref.invalidate(malaCatalogueProvider),
                  ),
                ),
            data:
                (either) => either.fold(
                  (failure) => _MalaAppBarScaffold(
                    child: _ErrorView(
                      message: failure.message,
                      onRetry: () => ref.invalidate(malaCatalogueProvider),
                    ),
                  ),
                  (mantras) => _buildLoaded(context, mantras),
                ),
          ),
        ),
      ),
    );
  }

  void _openMalaSettings(BuildContext context, Mantra mantra) {
    MalaSettingsSheet.show(context, mantra: mantra);
  }

  Widget _buildLoaded(BuildContext context, List<Mantra> mantras) {
    if (mantras.isEmpty) {
      return const _MalaAppBarScaffold(
        child: Center(child: Text('No mantras available')),
      );
    }

    if (!_initialisedIndex) {
      _initialisedIndex = true;
      if (widget.initialPresetId != null) {
        final i = mantras.indexWhere(
          (m) => m.presetId == widget.initialPresetId,
        );
        if (i >= 0) _index = i;
      }
    }
    _index = _index.clamp(0, mantras.length - 1);
    final mantra = mantras[_index];
    _trackOpened(mantra);

    ref.watch(
      prefetchBookmarkExistsProvider(
        BookmarkTarget(type: BookmarkType.accumulator, sourceId: mantra.presetId),
      ),
    );

    final language = Localizations.localeOf(context).languageCode;
    final counter = ref.watch(malaCounterProvider(mantra));
    final notifier = ref.read(malaCounterProvider(mantra).notifier);
    final settings = ref.watch(malaSettingsProvider);

    return Column(
      children: [
        _MalaAppBar(
          title: mantra.displayTitle(language),
          onMorePressed: () => _openMalaSettings(context, mantra),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 36,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: MantraSwitcher(
                        mantras: mantras,
                        language: language,
                        tibetanFontFamily: AppConfig.tibetanContentFont,
                        index: _index,
                        onIndexChanged: (next) => _switch(mantras, next),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _CounterBlock(
                  beadInRound: counter.beadInRound,
                  beadsPerRound: counter.beadsPerRound,
                  rounds: counter.rounds,
                  dimmed: counter.isSeeding,
                ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 42,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          height: constraints.maxHeight * 0.85,
                          width: double.infinity,
                          child:
                              counter.seedFailed
                                  ? _ErrorView(
                                    message: 'Could not load your count',
                                    onRetry: notifier.seed,
                                  )
                                  : MalaBeads(
                                    key: ValueKey(mantra.presetId),
                                    total: counter.total,
                                    beadInRound: counter.beadInRound,
                                    beadsPerRound: counter.beadsPerRound,
                                    enabled: !counter.isSeeding,
                                    beadImageUrl:
                                        counter.beadImageUrl ??
                                        mantra.beadImageUrl,
                                    beadImageBytes: counter.beadImageBytes,
                                    beadColor: const Color(0xFF8D6E63),
                                    threadColor: const Color(0xFFC62828),
                                    onTap:
                                        () => notifier.incrementBead(
                                          soundEnabled: settings.soundEnabled,
                                          vibrationEnabled:
                                              settings.vibrationEnabled,
                                        ),
                                  ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const _GroupAccumulationsBar(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupAccumulationsBar extends StatelessWidget {
  const _GroupAccumulationsBar();

  static const _avatarSize = 28.0;
  static const _avatarOverlap = 10.0;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 40,
        padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _avatarSize + _avatarOverlap,
              height: _avatarSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    child: _GroupAvatarPlaceholder(size: _avatarSize),
                  ),
                  Positioned(
                    left: _avatarOverlap,
                    child: _GroupAvatarPlaceholder(size: _avatarSize),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: iconColor),
          ],
        ),
      ),
    );
  }
}

class _GroupAvatarPlaceholder extends StatelessWidget {
  const _GroupAvatarPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: AppColors.surfaceWhite, width: 1.5),
      ),
    );
  }
}

class _CounterBlock extends StatelessWidget {
  const _CounterBlock({
    required this.beadInRound,
    required this.beadsPerRound,
    required this.rounds,
    required this.dimmed,
  });

  final int beadInRound;
  final int beadsPerRound;
  final int rounds;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final roundsLabel = l10n.mala_rounds_count(rounds);
    final color = theme.colorScheme.onSurface.withValues(
      alpha: dimmed ? 0.35 : 1.0,
    );
    return Semantics(
      label: l10n.mala_counter_semantics(
        beadInRound,
        beadsPerRound,
        roundsLabel,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$beadInRound/$beadsPerRound',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            roundsLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color.withValues(alpha: dimmed ? 0.35 : 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// App bar with a back button and the mantra name.
class _MalaAppBar extends StatelessWidget {
  const _MalaAppBar({required this.title, this.onMorePressed});
  final String title;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, size: 24),
            onPressed: onMorePressed,
          ),
        ],
      ),
    );
  }
}

/// Wraps non-loaded states with a minimal back-button app bar.
class _MalaAppBarScaffold extends StatelessWidget {
  const _MalaAppBarScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.message, required this.onRetry});
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'Something went wrong'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
