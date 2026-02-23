import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Font size adjustment button for the reader app bar
class ReaderFontSizeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ReaderFontSizeButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(PhosphorIconsRegular.textAa),
      tooltip: 'Font Size',
    );
  }
}
