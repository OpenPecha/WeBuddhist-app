import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet opened from the three-dot (⋮) button on a [PresetTimerCard].
///
/// Contains:
///   • "+ Add to my practices" action
///   • Bookmark action
class TimerMoreBottomSheet extends ConsumerStatefulWidget {
  const TimerMoreBottomSheet({
    super.key,
    required this.timer,
    this.onAddToPractices,
  });

  final PresetTimer timer;
  final VoidCallback? onAddToPractices;

  @override
  ConsumerState<TimerMoreBottomSheet> createState() =>
      _TimerMoreBottomSheetState();
}

class _TimerMoreBottomSheetState extends ConsumerState<TimerMoreBottomSheet> {
  bool _isBookmarking = false;

  Future<void> _bookmark() async {
    if (_isBookmarking) return;
    setState(() => _isBookmarking = true);
    try {
      await BookmarkController(
        ref: ref,
        context: context,
      ).bookmarkTimer(widget.timer.id);
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

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
            title: Text(
              'Add to my practices',
              style: theme.textTheme.bodyLarge,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              widget.onAddToPractices?.call();
            },
          ),

          // ── Bookmark ───────────────────────────────────────────────────
          _SectionDivider(theme: theme),
          ListTile(
            leading:
                _isBookmarking
                    ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                    : Icon(
                      AppAssets.bookmarkSimple,
                      color: theme.colorScheme.onSurface,
                    ),
            title: Text('Bookmark', style: theme.textTheme.bodyLarge),
            onTap: () async {
              HapticFeedback.lightImpact();
              final nav = Navigator.of(context);
              await _bookmark();
              if (mounted) nav.pop();
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

/// Shows the timer "more" bottom sheet.
void showTimerMoreBottomSheet(
  BuildContext context, {
  required PresetTimer timer,
  VoidCallback? onAddToPractices,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    useRootNavigator: true,
    builder:
        (_) => TimerMoreBottomSheet(
          timer: timer,
          onAddToPractices: onAddToPractices,
        ),
  );
}
