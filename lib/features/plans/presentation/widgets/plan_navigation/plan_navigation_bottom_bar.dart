import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// Shared bottom navigation strip used by both `ReaderScreen` (for
/// SOURCE_REFERENCE items) and `PlanTextScreen` (for inline TEXT items).
///
/// Renders one of three layouts based on the navigation context:
/// - **Full controls** (canSwipe): prev arrow, "X of N" + title, next arrow,
///   or a finish (✓) button on the last item.
/// - **Single item** (one navigable subtask): title + finish (✓) button.
/// - **Minimal** (no plan context, e.g. reader opened from search): title only.
///
/// All state — current index, total count, prev/next availability — is read
/// from [navigationContext] so the strip stays in sync regardless of which
/// screen hosts it.
class PlanNavigationBottomBar extends StatelessWidget {
  final NavigationContext? navigationContext;

  /// Title shown in the centre when there is no [navigationContext]
  /// (e.g. minimal reader). Ignored when a plan context is present —
  /// in that case the current item's title is used.
  final String fallbackTitle;

  /// Optional font family applied to the centre title (used by the reader
  /// to honour the script of the source text).
  final String? fallbackTitleFontFamily;

  final VoidCallback? onPreviousTap;
  final VoidCallback? onNextTap;
  final VoidCallback? onFinishedTap;

  const PlanNavigationBottomBar({
    super.key,
    required this.navigationContext,
    required this.fallbackTitle,
    this.fallbackTitleFontFamily,
    this.onPreviousTap,
    this.onNextTap,
    this.onFinishedTap,
  });

  @override
  Widget build(BuildContext context) {
    final ctx = navigationContext;
    final canSwipe = ctx != null && ctx.canSwipe;
    final isPlanNavigation = ctx != null && ctx.source == NavigationSource.plan;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: canSwipe
            ? _buildFullControls(context, ctx)
            : isPlanNavigation
                ? _buildSingleItemControls(context, ctx)
                : _buildMinimalTitle(context),
      ),
    );
  }

  // ─── Layouts ────────────────────────────────────────────────────────

  Widget _buildMinimalTitle(BuildContext context) {
    return Center(
      child: _TitleText(
        text: fallbackTitle,
        fontFamily: fallbackTitleFontFamily,
      ),
    );
  }

  Widget _buildSingleItemControls(BuildContext context, NavigationContext ctx) {
    final title = ctx.currentItem?.title ?? fallbackTitle;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _TitleText(
            text: title,
            fontFamily: fallbackTitleFontFamily,
          ),
        ),
        _NavigationButton(
          icon: Icons.check,
          isEnabled: true,
          onTap: onFinishedTap ?? () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Widget _buildFullControls(BuildContext context, NavigationContext ctx) {
    final hasPrevious = ctx.hasPreviousText;
    final hasNext = ctx.hasNextText;
    final progress =
        '${(ctx.currentTextIndex ?? 0) + 1} of ${ctx.planTextItems!.length}';
    final title = ctx.currentItem?.title ?? fallbackTitle;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (hasPrevious)
          _NavigationButton(
            icon: Icons.chevron_left,
            isEnabled: true,
            onTap: onPreviousTap ?? () => Navigator.of(context).maybePop(),
          ),
        Expanded(
          child: Column(
            children: [
              _TitleText(text: title),
              Text(
                progress,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withAlpha(180),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        if (hasNext)
          _NavigationButton(
            icon: Icons.chevron_right,
            isEnabled: true,
            onTap: onNextTap ?? () => Navigator.of(context).maybePop(),
          )
        else
          _NavigationButton(
            icon: Icons.check,
            isEnabled: true,
            onTap: onFinishedTap ?? () => Navigator.of(context).maybePop(),
          ),
      ],
    );
  }
}

class _TitleText extends StatelessWidget {
  final String text;
  final String? fontFamily;

  const _TitleText({required this.text, this.fontFamily});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isEnabled
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurface.withAlpha(80);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withAlpha(isEnabled ? 100 : 50),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
      ),
    );
  }
}
