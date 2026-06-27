import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

/// Search button for the reader app bar
class ReaderSearchButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ReaderSearchButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.search),
      tooltip: AppLocalizations.of(context)!.text_search,
    );
  }
}
