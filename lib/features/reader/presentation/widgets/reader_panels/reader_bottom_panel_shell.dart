import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Bottom-sheet-style shell for reader panels (Versions, Commentary).
///
/// Renders rounded top corners, a pill drag handle, a centered title and a
/// thin divider. Vertical drags on the handle area resize the panel via
/// [ReaderNotifier.updateSplitRatioOrDismiss], dismissing the panel via
/// [onDismiss] when the panel shrinks below the configured threshold.
class ReaderBottomPanelShell extends ConsumerStatefulWidget {
  const ReaderBottomPanelShell({
    super.key,
    required this.title,
    required this.params,
    required this.availableHeight,
    required this.onDismiss,
    required this.child,
  });

  final String title;
  final ReaderParams params;
  final double availableHeight;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  ConsumerState<ReaderBottomPanelShell> createState() =>
      _ReaderBottomPanelShellState();
}

class _ReaderBottomPanelShellState
    extends ConsumerState<ReaderBottomPanelShell> {
  bool _dismissedDuringDrag = false;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_dismissedDuringDrag) return;
    final notifier = ref.read(readerNotifierProvider(widget.params).notifier);
    final state = ref.read(readerNotifierProvider(widget.params));
    final currentMainHeight = widget.availableHeight * state.splitRatio;
    final newRatio =
        (currentMainHeight + details.delta.dy) / widget.availableHeight;

    final didDismiss = notifier.updateSplitRatioOrDismiss(
      ratio: newRatio,
      availableHeight: widget.availableHeight,
      onDismiss: () {
        HapticFeedback.lightImpact();
        widget.onDismiss();
      },
    );

    if (didDismiss) {
      _dismissedDuringDrag = true;
    }
  }

  void _handleDragEnd(DragEndDetails _) {
    _dismissedDuringDrag = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = ReaderPanelConstants.dividerColor(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.only(
        topLeft: ReaderPanelConstants.topCornerRadius,
        topRight: ReaderPanelConstants.topCornerRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _handleDragUpdate,
            onVerticalDragEnd: _handleDragEnd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: ReaderPanelConstants.dragHandleWidth,
                    height: ReaderPanelConstants.dragHandleHeight,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.25,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    8,
                    4,
                    ReaderPanelConstants.horizontalPadding,
                    12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          PhosphorIconsRegular.arrowLeft,
                          size: 20,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.onDismiss();
                        },
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        tooltip: context.l10n.back,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: dividerColor),
              ],
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
