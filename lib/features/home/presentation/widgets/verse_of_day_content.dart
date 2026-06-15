import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Typography for verse-of-day content, derived from the active locale.
class VerseOfDayTypography {
  const VerseOfDayTypography({
    required this.contentFont,
    required this.systemFont,
    required this.verseFontSize,
    required this.attributionFontSize,
  });

  final String? contentFont;
  final String? systemFont;
  final double verseFontSize;
  final double attributionFontSize;

  factory VerseOfDayTypography.fromLanguageCode(String languageCode) {
    return VerseOfDayTypography(
      contentFont: getFontFamily(languageCode),
      systemFont: getSystemFontFamily(languageCode),
      verseFontSize: languageCode == 'bo' ? 18.0 : 16.0,
      attributionFontSize: languageCode == 'bo' ? 14.0 : 13.0,
    );
  }
}

/// Shared verse image, quote, attribution, and optional WeBuddhist branding.
class VerseOfDayContent extends StatelessWidget {
  const VerseOfDayContent({
    super.key,
    required this.verseOfDay,
    required this.typography,
    required this.verseColor,
    required this.attributionColor,
    this.imageAspectRatio = 1.65,
    this.showBranding = false,
    this.textPadding = const EdgeInsets.fromLTRB(24, 24, 24, 16),
    this.brandingBottomPadding = 0,
    this.footerAction,
  });

  final VerseOfDay verseOfDay;
  final VerseOfDayTypography typography;
  final Color verseColor;
  final Color attributionColor;
  final double imageAspectRatio;
  final bool showBranding;
  final EdgeInsets textPadding;
  final double brandingBottomPadding;
  final Widget? footerAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: imageAspectRatio,
          child: CachedNetworkImageWidget(
            imageUrl: verseOfDay.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
        Padding(
          padding: textPadding,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: footerAction != null ? 32 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '"${verseOfDay.verse}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: typography.verseFontSize,
                        fontWeight: FontWeight.w400,
                        fontFamily: typography.contentFont,
                        color: verseColor,
                        height: 1.55,
                      ),
                    ),
                    if (verseOfDay.groupTitle != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        '~ ${verseOfDay.groupTitle}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: typography.attributionFontSize,
                          fontWeight: FontWeight.w400,
                          fontFamily: typography.systemFont,
                          color: attributionColor,
                        ),
                      ),
                    ],
                    if (showBranding) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.only(bottom: brandingBottomPadding),
                        child: const VerseShareBranding(),
                      ),
                    ],
                  ],
                ),
              ),
              if (footerAction != null)
                Positioned(right: 0, bottom: 0, child: footerAction!),
            ],
          ),
        ),
      ],
    );
  }
}

/// WeBuddhist logo and "Shared from" label used in shareable verse images.
class VerseShareBranding extends StatelessWidget {
  const VerseShareBranding({
    super.key,
    this.logoSize = 28,
    this.sharedFromFontSize = 11,
    this.appTitleFontSize = 13,
    this.sharedFromColor = Colors.black45,
    this.appTitleColor = Colors.black87,
  });

  final double logoSize;
  final double sharedFromFontSize;
  final double appTitleFontSize;
  final Color sharedFromColor;
  final Color appTitleColor;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(AppAssets.weBuddhistLogo, width: logoSize, height: logoSize),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.shared_from,
              style: TextStyle(fontSize: sharedFromFontSize, color: sharedFromColor),
            ),
            Text(
              localizations.appTitle,
              style: TextStyle(
                fontSize: appTitleFontSize,
                fontWeight: FontWeight.w700,
                color: appTitleColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
