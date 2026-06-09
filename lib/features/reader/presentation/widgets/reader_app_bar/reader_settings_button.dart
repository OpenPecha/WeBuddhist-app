import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

class ReaderSettingsButton extends StatelessWidget {
  const ReaderSettingsButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(AppAssets.readerVersionSettings),
      tooltip: AppLocalizations.of(context)!.reader_settings_tooltip,
    );
  }
}
