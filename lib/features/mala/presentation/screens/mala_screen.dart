import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mala_beads.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mala_skeleton.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mantra_switcher.dart';
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
      body: SafeArea(
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
    );
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

    final language = Localizations.localeOf(context).languageCode;
    final counter = ref.watch(malaCounterProvider(mantra));
    final notifier = ref.read(malaCounterProvider(mantra).notifier);

    return Column(
      children: [
        _MalaAppBar(title: mantra.localizedName(language)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mantra + transliteration switcher: 40% of the space below
                // the header, with the text centered between the chevrons.
                Expanded(
                  flex: 40,
                  child: MantraSwitcher(
                    tibetan: mantra.tibetan,
                    tibetanFontFamily: AppConfig.tibetanContentFont,
                    transliteration:
                        mantra.transliteration(language) ??
                        mantra.localizedName(language),
                    canGoPrevious: _index > 0,
                    canGoNext: _index < mantras.length - 1,
                    onPrevious: () => _switch(mantras, _index - 1),
                    onNext: () => _switch(mantras, _index + 1),
                  ),
                ),
                // Counter + bead arc: the remaining 60%.
                Expanded(
                  flex: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Counter block (left-aligned).
                      _CounterBlock(
                        beadInRound: counter.beadInRound,
                        beadsPerRound: counter.beadsPerRound,
                        rounds: counter.rounds,
                        dimmed: counter.isSeeding,
                      ),
                      const SizedBox(height: 16),
                      // Bead arc.
                      Expanded(
                        child:
                            counter.seedFailed
                                ? _ErrorView(
                                  message: 'Could not load your count',
                                  onRetry: notifier.seed,
                                )
                                : MalaBeads(
                                  total: counter.total,
                                  beadInRound: counter.beadInRound,
                                  beadsPerRound: counter.beadsPerRound,
                                  enabled: !counter.isSeeding,
                                  // Per-user image from the accumulator detail
                                  // wins; fall back to the preset's image.
                                  beadImageUrl:
                                      counter.beadImageUrl ??
                                      mantra.beadImageUrl,
                                  beadColor: const Color(0xFF8D6E63),
                                  threadColor: const Color(0xFFC62828),
                                  onTap: notifier.incrementBead,
                                ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
    final color = theme.colorScheme.onSurface.withValues(
      alpha: dimmed ? 0.35 : 1.0,
    );
    return Semantics(
      label: 'Count $beadInRound of $beadsPerRound, $rounds rounds',
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
            rounds == 1 ? '1 round' : '$rounds rounds',
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
  const _MalaAppBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
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
          const SizedBox(width: 48),
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
