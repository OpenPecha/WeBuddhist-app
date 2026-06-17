import 'package:flutter/material.dart';

/// Chevron + transliteration header row used to switch the active mantra.
class MantraSwitcher extends StatelessWidget {
  const MantraSwitcher({
    super.key,
    required this.transliteration,
    required this.onPrevious,
    required this.onNext,
    this.canGoPrevious = true,
    this.canGoNext = true,
  });

  final String transliteration;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoPrevious;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _Chevron(
          icon: Icons.chevron_left,
          onTap: canGoPrevious ? onPrevious : null,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              transliteration,
              key: ValueKey(transliteration),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        _Chevron(
          icon: Icons.chevron_right,
          onTap: canGoNext ? onNext : null,
        ),
      ],
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 32),
      color: color,
      disabledColor: color.withValues(alpha: 0.25),
      splashRadius: 24,
    );
  }
}
