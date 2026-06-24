import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_explore_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_container.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PracticeAccumulationsSection extends ConsumerWidget {
  const PracticeAccumulationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = ref.watch(localeProvider).languageCode;
    final accumulatorsAsync = ref.watch(practiceExploreAccumulatorsProvider);

    return accumulatorsAsync.when(
      data:
          (either) => either.fold((_) => const SizedBox.shrink(), (mantras) {
            if (mantras.isEmpty) return const SizedBox.shrink();
            return PracticeSectionContainer(
              title: 'Accumulations',
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: mantras.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final mantra = mantras[index];
                    return _AccumulationItem(
                      mantra: mantra,
                      language: language,
                      onTap: () => _navigateToMala(context, ref, mantra),
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

  void _navigateToMala(BuildContext context, WidgetRef ref, Mantra mantra) {
    final isGuest = ref.read(authProvider).isGuest;
    if (isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }
    context.push('/mala', extra: {'presetId': mantra.presetId});
  }
}

class _AccumulationItem extends StatelessWidget {
  const _AccumulationItem({
    required this.mantra,
    required this.language,
    required this.onTap,
  });

  final Mantra mantra;
  final String language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final beadUrl = mantra.mantra?.beadImageUrl ?? mantra.beadImageUrl;
    final title = mantra.displayTitle(language);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            ClipOval(
              child:
                  beadUrl != null && beadUrl.isNotEmpty
                      ? CachedNetworkImageWidget(
                        imageUrl: beadUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.spa, size: 24),
                      ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
