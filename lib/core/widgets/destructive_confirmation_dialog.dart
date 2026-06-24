import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shows a styled destructive confirmation dialog.
///
/// Returns `true` when the action succeeds, `false` when [onConfirmed] returns
/// `false` (show error feedback after the dialog closes), or `null` when
/// cancelled or dismissed. With [onConfirmed], the dialog stays open with a
/// loading spinner until the callback completes, then closes.
Future<bool?> showDestructiveConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool barrierDismissible = true,
  Future<bool> Function()? onConfirmed,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = context.l10n;

  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder:
        (dialogContext) => DestructiveConfirmationDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel ?? l10n.delete,
          cancelLabel: cancelLabel ?? l10n.cancel,
          isDark: isDark,
          onConfirmed: onConfirmed,
        ),
  );
}

class DestructiveConfirmationDialog extends StatefulWidget {
  const DestructiveConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDark,
    this.onConfirmed,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDark;
  final Future<bool> Function()? onConfirmed;

  @override
  State<DestructiveConfirmationDialog> createState() =>
      _DestructiveConfirmationDialogState();
}

class _DestructiveConfirmationDialogState
    extends State<DestructiveConfirmationDialog> {
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    if (widget.onConfirmed != null) {
      setState(() => _isLoading = true);
      try {
        final succeeded = await widget.onConfirmed!();
        if (!mounted) return;
        Navigator.of(context).pop(succeeded);
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
      backgroundColor:
          widget.isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.inter(
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.message,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _handleConfirm,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: const BorderSide(color: AppColors.grey300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child:
                    _isLoading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red.shade600,
                          ),
                        )
                        : Text(
                          widget.confirmLabel,
                          style: const TextStyle(fontSize: 15),
                        ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(null),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      widget.isDark ? AppColors.textPrimaryDark : Colors.black,
                  side: const BorderSide(color: AppColors.grey300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  widget.cancelLabel,
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        widget.isDark
                            ? AppColors.textPrimaryDark
                            : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
