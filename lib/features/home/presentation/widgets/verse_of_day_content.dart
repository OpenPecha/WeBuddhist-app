import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography for verse-of-day content, derived from the active locale.
class VerseOfDayTypography {
  const VerseOfDayTypography({
    required this.contentFont,
    required this.systemFont,
    required this.verseFontSize,
    required this.attributionFontSize,
    this.useContentFontForAttribution = false,
    this.useGoogleJomolhari = false,
  });

  final String? contentFont;
  final String? systemFont;
  final double verseFontSize;
  final double attributionFontSize;
  final bool useContentFontForAttribution;
  final bool useGoogleJomolhari;

  factory VerseOfDayTypography.fromLanguageCode(String languageCode) {
    final isTibetan = languageCode == AppConfig.tibetanLanguageCode;

    return VerseOfDayTypography(
      contentFont: getFontFamily(languageCode),
      systemFont: getSystemFontFamily(languageCode),
      verseFontSize: isTibetan ? 18.0 : 16.0,
      attributionFontSize: isTibetan ? 14.0 : 16.0,
    );
  }

  /// Home card typography. Tibetan uses Google Jomolhari for verse and attribution.
  factory VerseOfDayTypography.forCard(
    String languageCode, {
    double? verseFontSize,
    double? attributionFontSize,
  }) {
    final base = VerseOfDayTypography.fromLanguageCode(languageCode);
    final isTibetan = languageCode == AppConfig.tibetanLanguageCode;

    if (!isTibetan) return base;

    return VerseOfDayTypography(
      contentFont: base.contentFont,
      systemFont: base.systemFont,
      verseFontSize: verseFontSize ?? base.verseFontSize,
      attributionFontSize: attributionFontSize ?? base.attributionFontSize,
      useContentFontForAttribution: true,
      useGoogleJomolhari: true,
    );
  }

  /// Share preview typography. Larger sizes; Tibetan uses Google Jomolhari.
  factory VerseOfDayTypography.forShare(String languageCode) {
    final base = VerseOfDayTypography.fromLanguageCode(languageCode);
    final isTibetan = languageCode == AppConfig.tibetanLanguageCode;

    return VerseOfDayTypography(
      contentFont: base.contentFont,
      systemFont: base.systemFont,
      verseFontSize: isTibetan ? 20.0 : 18.0,
      attributionFontSize: isTibetan ? 16.0 : 15.0,
      useContentFontForAttribution: true,
      useGoogleJomolhari: isTibetan,
    );
  }

  TextStyle verseTextStyle({required Color color}) {
    final baseStyle = TextStyle(
      fontSize: verseFontSize,
      fontWeight: FontWeight.w400,
      height: useGoogleJomolhari ? getLineHeight(AppConfig.tibetanLanguageCode) : null,
      color: color,
    );

    if (useGoogleJomolhari) {
      return GoogleFonts.jomolhari(textStyle: baseStyle);
    }

    return baseStyle.copyWith(fontFamily: contentFont);
  }

  TextStyle attributionTextStyle({
    required Color color,
    required bool useContentFontForAttribution,
  }) {
    final baseStyle = TextStyle(
      fontSize: attributionFontSize,
      fontWeight: FontWeight.w600,
      height:
          useGoogleJomolhari && useContentFontForAttribution
              ? getLineHeight(AppConfig.tibetanLanguageCode)
              : null,
      color: color,
    );

    if (useGoogleJomolhari && useContentFontForAttribution) {
      return GoogleFonts.jomolhari(textStyle: baseStyle);
    }

    return baseStyle.copyWith(
      fontFamily:
          useContentFontForAttribution ? contentFont : systemFont,
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
    this.useContentFontForAttribution = false,
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
  final bool useContentFontForAttribution;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                verseOfDay.verse,
                textAlign: TextAlign.center,
                style: typography.verseTextStyle(color: verseColor),
              ),
              if (verseOfDay.groupTitle != null || footerAction != null) ...[
                const SizedBox(height: 16),
                _AttributionFooterRow(
                  attribution:
                      verseOfDay.groupTitle != null
                          ? '~ ${verseOfDay.groupTitle}'
                          : null,
                  typography: typography,
                  attributionColor: attributionColor,
                  useContentFontForAttribution: useContentFontForAttribution,
                  footerAction: footerAction,
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
      ],
    );
  }
}

class _AttributionFooterRow extends StatelessWidget {
  const _AttributionFooterRow({
    required this.typography,
    required this.attributionColor,
    required this.useContentFontForAttribution,
    this.attribution,
    this.footerAction,
  });

  final String? attribution;
  final VerseOfDayTypography typography;
  final Color attributionColor;
  final bool useContentFontForAttribution;
  final Widget? footerAction;

  TextStyle _attributionStyle(bool useContentFontForAttribution) =>
      typography.attributionTextStyle(
        color: attributionColor,
        useContentFontForAttribution: useContentFontForAttribution,
      );

  @override
  Widget build(BuildContext context) {
    if (footerAction == null) {
      return Text(
        attribution!,
        textAlign: TextAlign.center,
        style: _attributionStyle(useContentFontForAttribution),
      );
    }

    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (attribution != null)
            Text(
              attribution!,
              textAlign: TextAlign.center,
              style: _attributionStyle(useContentFontForAttribution),
            ),
          Positioned(right: 0, child: footerAction!),
        ],
      ),
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
        Image.asset(
          AppAssets.weBuddhistLogo,
          width: logoSize,
          height: logoSize,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.shared_from,
              style: TextStyle(
                fontSize: sharedFromFontSize,
                color: sharedFromColor,
              ),
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
