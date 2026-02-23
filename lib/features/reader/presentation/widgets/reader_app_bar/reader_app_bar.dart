import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_bottom_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_button.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_language_button.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_search_button.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// App bar overlay for the reader screen - animates in/out based on scroll
class ReaderAppBarOverlay extends ConsumerWidget {
  final ReaderParams params;
  final int? colorIndex;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onLanguagePressed;

  const ReaderAppBarOverlay({
    super.key,
    required this.params,
    this.colorIndex,
    this.onSearchPressed,
    this.onLanguagePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerNotifierProvider(params));
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    // Get the border color from the color index
    final borderColor = colorIndex != null
        ? TextScreenConstants.collectionCyclingColors[colorIndex! % 9]
        : TextScreenConstants.primaryBorderColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          elevation: ReaderConstants.appBarElevation,
          scrolledUnderElevation: ReaderConstants.appBarElevation,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              // Clear selection states before navigating back
              notifier.selectSegment(null);
              notifier.closeCommentary();
              context.pop();
            },
          ),
          toolbarHeight: ReaderConstants.appBarToolbarHeight,
          actions: [
            ReaderSearchButton(
              onPressed: onSearchPressed ?? () => _handleSearch(context, ref),
            ),
            const SizedBox(width: 4),
            ReaderFontSizeButton(
              onPressed: () => _showFontSizeBottomSheet(context, ref),
            ),
            if (state.textDetail != null) ...[
              const SizedBox(width: 4),
              ReaderLanguageButton(
                language: state.textDetail!.language,
                onPressed:
                    onLanguagePressed ?? () => _handleLanguageSelection(context, ref),
              ),
            ],
            const SizedBox(width: 12),
          ],
        ),
        // Bottom border
        Container(
          height: ReaderConstants.appBarBottomHeight,
          color: borderColor,
        ),
      ],
    );
  }

  void _handleSearch(BuildContext context, WidgetRef ref) {
    // Default search implementation - can be overridden via callback
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    // Close split view and selection before search
    notifier.closeCommentary();
    notifier.selectSegment(null);
  }

  void _showFontSizeBottomSheet(BuildContext context, WidgetRef ref) {
    final locale = ref.read(localeProvider);
    final language = locale.languageCode;
    showFontSizeBottomSheet(context, language);
  }

  void _handleLanguageSelection(BuildContext context, WidgetRef ref) {
    // Default implementation - can be overridden via callback
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    // Close split view and selection before language selection
    notifier.closeCommentary();
    notifier.selectSegment(null);
  }
}

/// SliverAppBar version for use with CustomScrollView (kept for reference)
class ReaderAppBar extends ConsumerWidget {
  final ReaderParams params;
  final int? colorIndex;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onLanguagePressed;

  const ReaderAppBar({
    super.key,
    required this.params,
    this.colorIndex,
    this.onSearchPressed,
    this.onLanguagePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerNotifierProvider(params));
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    // Get the border color from the color index
    final borderColor = colorIndex != null
        ? TextScreenConstants.collectionCyclingColors[colorIndex! % 9]
        : TextScreenConstants.primaryBorderColor;

    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: ReaderConstants.appBarElevation,
      scrolledUnderElevation: ReaderConstants.appBarElevation,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
          // Clear selection states before navigating back
          notifier.selectSegment(null);
          notifier.closeCommentary();
          context.pop();
        },
      ),
      toolbarHeight: ReaderConstants.appBarToolbarHeight,
      actions: [
        ReaderSearchButton(
          onPressed: onSearchPressed ?? () => _handleSearch(context, ref),
        ),
        const SizedBox(width: 4),
        ReaderFontSizeButton(
          onPressed: () => _showFontSizeBottomSheet(context, ref),
        ),
        if (state.textDetail != null) ...[
          const SizedBox(width: 4),
          ReaderLanguageButton(
            language: state.textDetail!.language,
            onPressed:
                onLanguagePressed ?? () => _handleLanguageSelection(context, ref),
          ),
        ],
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(ReaderConstants.appBarBottomHeight),
        child: Container(
          height: ReaderConstants.appBarBottomHeight,
          color: borderColor,
        ),
      ),
    );
  }

  void _handleSearch(BuildContext context, WidgetRef ref) {
    // Default search implementation - can be overridden via callback
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    // Close split view and selection before search
    notifier.closeCommentary();
    notifier.selectSegment(null);
  }

  void _showFontSizeBottomSheet(BuildContext context, WidgetRef ref) {
    final locale = ref.read(localeProvider);
    final language = locale.languageCode;
    showFontSizeBottomSheet(context, language);
  }

  void _handleLanguageSelection(BuildContext context, WidgetRef ref) {
    // Default implementation - can be overridden via callback
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    // Close split view and selection before language selection
    notifier.closeCommentary();
    notifier.selectSegment(null);
  }
}
