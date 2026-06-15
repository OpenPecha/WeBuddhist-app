import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_of_day_content.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_share_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerseOfDayCard extends ConsumerWidget {
  const VerseOfDayCard({super.key, required this.verseOfDay});

  final VerseOfDay verseOfDay;

  static const _borderRadius = 24.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(localeProvider).languageCode;
    final typography = VerseOfDayTypography.fromLanguageCode(languageCode);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_borderRadius),
        child: ColoredBox(
          color: colorScheme.surface,
          child: VerseOfDayContent(
            verseOfDay: verseOfDay,
            typography: typography,
            verseColor: colorScheme.onSurface,
            attributionColor: colorScheme.onSurfaceVariant,
            footerAction: IconButton(
              onPressed: () => showVerseShareSheet(context, verseOfDay),
              icon: const Icon(Icons.share_outlined),
              color: colorScheme.onSurfaceVariant,
              iconSize: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ),
      ),
    );
  }
}
