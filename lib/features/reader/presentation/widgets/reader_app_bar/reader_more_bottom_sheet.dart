import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_bottom_sheet.dart';
import 'package:flutter_pecha/features/recitation/presentation/controllers/recitation_save_controller.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Bottom sheet opened from the reader's three-dot (⋮) button.
///
/// Contains:
///   • Font-size A / A buttons
///   • "+ Add to my practices" action
///   • Bookmark action
class ReaderMoreBottomSheet extends ConsumerStatefulWidget {
  const ReaderMoreBottomSheet({super.key, required this.textId});

  final String textId;

  @override
  ConsumerState<ReaderMoreBottomSheet> createState() =>
      _ReaderMoreBottomSheetState();
}

class _ReaderMoreBottomSheetState extends ConsumerState<ReaderMoreBottomSheet> {
  bool _isSaving = false;
  bool _isBookmarking = false;

  // ── font size helpers ──────────────────────────────────────────────────────

  int _stepIndex(double fontSize) {
    for (int i = 0; i < ReaderFontSizeBottomSheet.fontSizeSteps.length; i++) {
      if ((fontSize - ReaderFontSizeBottomSheet.fontSizeSteps[i]).abs() < 0.5) {
        return i;
      }
    }
    int closest = ReaderFontSizeBottomSheet.defaultStepIndex;
    double minDiff = double.infinity;
    for (int i = 0; i < ReaderFontSizeBottomSheet.fontSizeSteps.length; i++) {
      final d = (fontSize - ReaderFontSizeBottomSheet.fontSizeSteps[i]).abs();
      if (d < minDiff) {
        minDiff = d;
        closest = i;
      }
    }
    return closest;
  }

  // ── bookmark ───────────────────────────────────────────────────────────────

  Future<void> _bookmark() async {
    if (_isBookmarking) return;
    setState(() => _isBookmarking = true);
    try {
      await BookmarkController(ref: ref, context: context)
          .bookmarkText(widget.textId);
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  // ── add-to-practices ───────────────────────────────────────────────────────

  Future<void> _toggleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final savedAsync = ref.read(savedRecitationsFutureProvider);
      final isSaved =
          savedAsync.valueOrNull?.fold(
            (_) => false,
            (list) => list.any((r) => r.textId == widget.textId),
          ) ??
          false;

      await RecitationSaveController(
        ref: ref,
        context: context,
      ).toggleSave(textId: widget.textId, isSaved: isSaved);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fontSize = ref.watch(fontSizeProvider);
    final stepIndex = _stepIndex(fontSize);
    final canDecrease = stepIndex > 0;
    final canIncrease =
        stepIndex < ReaderFontSizeBottomSheet.fontSizeSteps.length - 1;

    final savedAsync = ref.watch(savedRecitationsFutureProvider);
    final isSaved =
        savedAsync.valueOrNull?.fold(
          (_) => false,
          (list) => list.any((r) => r.textId == widget.textId),
        ) ??
        false;

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

          // ── Font size row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _FontSizeButton(
                    label: 'A',
                    fontSize: 16,
                    isEnabled: canDecrease,
                    onTap:
                        canDecrease
                            ? () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(fontSizeProvider.notifier)
                                  .setFontSize(
                                    ReaderFontSizeBottomSheet
                                        .fontSizeSteps[stepIndex - 1],
                                  );
                            }
                            : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FontSizeButton(
                    label: 'A',
                    fontSize: 26,
                    isEnabled: canIncrease,
                    onTap:
                        canIncrease
                            ? () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(fontSizeProvider.notifier)
                                  .setFontSize(
                                    ReaderFontSizeBottomSheet
                                        .fontSizeSteps[stepIndex + 1],
                                  );
                            }
                            : null,
                  ),
                ),
              ],
            ),
          ),

          // ── Add to my practices ────────────────────────────────────────
          _SectionDivider(theme: theme),
          ListTile(
            leading:
                _isSaving
                    ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                    : Icon(
                      isSaved ? PhosphorIconsFill.checkCircle : AppAssets.plus,
                      color: theme.colorScheme.onSurface,
                    ),
            title: Text(
              isSaved ? 'Added to practices' : 'Add to my practices',
              style: theme.textTheme.bodyLarge,
            ),
            onTap: _toggleSave,
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
            onTap: () {
              HapticFeedback.lightImpact();
              _bookmark();
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

class _FontSizeButton extends StatelessWidget {
  const _FontSizeButton({
    required this.label,
    required this.fontSize,
    required this.isEnabled,
    this.onTap,
  });

  final String label;
  final double fontSize;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color:
                isEnabled
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color:
                  isEnabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the reader "more" bottom sheet.
void showReaderMoreBottomSheet(BuildContext context, {required String textId}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ReaderMoreBottomSheet(textId: textId),
  );
}
