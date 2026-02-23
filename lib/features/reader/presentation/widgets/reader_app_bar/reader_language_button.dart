import 'package:flutter/material.dart';

/// Language selector button for the reader app bar
class ReaderLanguageButton extends StatelessWidget {
  final String language;
  final VoidCallback onPressed;

  const ReaderLanguageButton({
    super.key,
    required this.language,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              language.toUpperCase(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
