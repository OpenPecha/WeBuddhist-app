import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

/// Font size adjustment button for the reader app bar
class ReaderFontSizeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ReaderFontSizeButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(AppAssets.readerFontSize),
      tooltip: AppLocalizations.of(context)!.reader_font_size_tooltip,
    );
  }
}
