import 'package:flutter/material.dart';

/// Mantra display + chevron switcher. The Tibetan script (when present) and the
/// transliteration are stacked and centered between the previous/next chevrons,
/// vertically centered within whatever space the parent allocates.
class MantraSwitcher extends StatelessWidget {
  const MantraSwitcher({
    super.key,
    required this.transliteration,
    required this.onPrevious,
    required this.onNext,
    this.tibetan,
    this.tibetanFontFamily,
    this.canGoPrevious = true,
    this.canGoNext = true,
  });

  /// Tibetan script for the mantra, shown above the transliteration. Optional.
  final String? tibetan;
  final String? tibetanFontFamily;
  final String transliteration;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoPrevious;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Chevron(
          icon: Icons.chevron_left,
          onTap: canGoPrevious ? onPrevious : null,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Column(
              key: ValueKey(transliteration),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tibetan != null) ...[
                  Semantics(
                    label: 'Mantra',
                    child: Text(
                      tibetan!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontFamily: tibetanFontFamily,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  transliteration,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
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
