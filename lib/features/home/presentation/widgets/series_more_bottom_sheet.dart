import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';

/// Bottom sheet opened from the three-dot (⋮) button on the series detail
/// screen.
///
/// Contains:
///   • "+ Add to my practices" action
///   • Bookmark action
///
/// Both callbacks fire after the sheet is dismissed so any feedback
/// (snackbar / login drawer) is shown on the underlying screen rather than
/// behind the closing modal.
class SeriesMoreBottomSheet extends StatelessWidget {
  const SeriesMoreBottomSheet({
    super.key,
    this.onAddToPractices,
    this.onBookmark,
  });

  final VoidCallback? onAddToPractices;
  final VoidCallback? onBookmark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Add to my practices ────────────────────────────────────────
          _SectionDivider(theme: theme),
          ListTile(
            leading: Icon(AppAssets.plus, color: theme.colorScheme.onSurface),
            title: Text('Add to my practices', style: theme.textTheme.bodyLarge),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              onAddToPractices?.call();
            },
          ),

          // ── Bookmark ───────────────────────────────────────────────────
          _SectionDivider(theme: theme),
          ListTile(
            leading: Icon(
              AppAssets.bookmarkSimple,
              color: theme.colorScheme.onSurface,
            ),
            title: Text('Bookmark', style: theme.textTheme.bodyLarge),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              onBookmark?.call();
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: theme.dividerColor);
}

/// Shows the series "more" bottom sheet.
void showSeriesMoreBottomSheet(
  BuildContext context, {
  VoidCallback? onAddToPractices,
  VoidCallback? onBookmark,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (_) => SeriesMoreBottomSheet(
          onAddToPractices: onAddToPractices,
          onBookmark: onBookmark,
        ),
  );
}
