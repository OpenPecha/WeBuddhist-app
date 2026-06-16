import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/app_theme.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_of_day_content.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class VerseShareSheet extends StatefulWidget {
  const VerseShareSheet({super.key, required this.verseOfDay});

  final VerseOfDay verseOfDay;

  @override
  State<VerseShareSheet> createState() => _VerseShareSheetState();
}

class _VerseShareSheetState extends State<VerseShareSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareQuote() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    File? tempFile;
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      if (imageBytes == null || !mounted) return;

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/verse_share_${DateTime.now().millisecondsSinceEpoch}.png';
      tempFile = File(imagePath);
      await tempFile.writeAsBytes(imageBytes);

      if (!mounted) return;

      final sharePositionOrigin = getSharePositionOrigin(
        context: context,
        globalKey: _shareButtonKey,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.verse_share_error),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final typography = VerseOfDayTypography.fromLanguageCode(languageCode);
    final locale = Localizations.localeOf(context);
    final lightTheme = AppTheme.lightTheme(locale);
    final lightColorScheme = lightTheme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Theme(
                data: lightTheme,
                child: Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    color: lightColorScheme.surface,
                    padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: VerseOfDayContent(
                          verseOfDay: widget.verseOfDay,
                          typography: VerseOfDayTypography(
                            contentFont: typography.contentFont,
                            systemFont: typography.systemFont,
                            verseFontSize: languageCode == 'bo' ? 20.0 : 18.0,
                            attributionFontSize:
                                languageCode == 'bo' ? 16.0 : 15.0,
                          ),
                          verseColor: Colors.black87,
                          attributionColor: Colors.black87,
                          imageAspectRatio: 1.15,
                          useContentFontForAttribution: true,
                          textPadding: const EdgeInsets.fromLTRB(
                            28,
                            32,
                            28,
                            36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const VerseShareBranding(
                        logoSize: 32,
                        sharedFromFontSize: 12,
                        appTitleFontSize: 14,
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  key: _shareButtonKey,
                  onPressed: _isSharing ? null : _shareQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.greyLight,
                    foregroundColor: colorScheme.onSurface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon:
                      _isSharing
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onSurface,
                            ),
                          )
                          : Icon(AppAssets.share, size: 22),
                  label: Text(
                    localizations.share_this_quote,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Shows the verse share bottom sheet.
void showVerseShareSheet(BuildContext context, VerseOfDay verseOfDay) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => VerseShareSheet(verseOfDay: verseOfDay),
  );
}
