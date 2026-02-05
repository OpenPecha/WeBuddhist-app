import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_button.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_language_button.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_search_button.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/font_size_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// App bar for the reader screen
class ReaderAppBar extends ConsumerWidget implements PreferredSizeWidget {
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
  Size get preferredSize => const Size.fromHeight(
    ReaderConstants.appBarToolbarHeight + ReaderConstants.appBarBottomHeight,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerNotifierProvider(params));
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    // Get the border color from the color index
    final borderColor = colorIndex != null
        ? TextScreenConstants.collectionCyclingColors[colorIndex! % 9]
        : TextScreenConstants.primaryBorderColor;

    return AppBar(
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
        ReaderFontSizeButton(
          onPressed: () => _showFontSizeSelector(context, ref),
        ),
        if (state.textDetail != null)
          ReaderLanguageButton(
            language: state.textDetail!.language,
            onPressed: onLanguagePressed ?? () => _handleLanguageSelection(context, ref),
          ),
      ],
      actionsPadding: TextScreenConstants.appBarActionsPadding,
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

    // Navigate to search
    // This will be handled by the screen that provides the callback
  }

  void _showFontSizeSelector(BuildContext context, WidgetRef ref) {
    final locale = ref.read(localeProvider);
    final language = locale.languageCode;
    showDialog(
      context: context,
      builder: (context) => FontSizeSelector(language: language),
    );
  }

  void _handleLanguageSelection(BuildContext context, WidgetRef ref) {
    // Default implementation - can be overridden via callback
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    // Close split view and selection before language selection
    notifier.closeCommentary();
    notifier.selectSegment(null);

    // Navigation to version selection will be handled by screen
  }
}
