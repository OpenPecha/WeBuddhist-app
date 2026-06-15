import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerseOfDayCard extends ConsumerWidget {
  const VerseOfDayCard({super.key, required this.verseOfDay});

  final VerseOfDay verseOfDay;

  static const _borderRadius = 24.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;
    final contentFont = getFontFamily(languageCode);
    final systemFont = getSystemFontFamily(languageCode);
    final verseFontSize = languageCode == 'bo' ? 18.0 : 16.0;
    final attributionFontSize = languageCode == 'bo' ? 14.0 : 13.0;

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_borderRadius),
        child: ColoredBox(
          color: colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1.65,
                child: CachedNetworkImageWidget(
                  imageUrl: verseOfDay.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '"${verseOfDay.verse}"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: verseFontSize,
                              fontWeight: FontWeight.w400,
                              fontFamily: contentFont,
                              color: colorScheme.onSurface,
                              height: 1.55,
                            ),
                          ),
                          if (verseOfDay.groupTitle != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              '~ ${verseOfDay.groupTitle}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: attributionFontSize,
                                fontWeight: FontWeight.w400,
                                fontFamily: systemFont,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Positioned(
                    //   right: 0,
                    //   bottom: 0,
                    //   child: IconButton(
                    //     onPressed: null,
                    //     icon: const Icon(Icons.share_outlined),
                    //     color: colorScheme.onSurfaceVariant,
                    //     iconSize: 22,
                    //     padding: EdgeInsets.zero,
                    //     constraints: const BoxConstraints(
                    //       minWidth: 32,
                    //       minHeight: 32,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
