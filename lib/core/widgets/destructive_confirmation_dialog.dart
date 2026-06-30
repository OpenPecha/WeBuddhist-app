import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

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
  return _showConfirmationDialog(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    barrierDismissible: barrierDismissible,
    onConfirmed: onConfirmed,
    isDestructive: true,
  );
}

/// Shows a styled confirmation dialog with neutral confirm styling.
Future<bool?> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool barrierDismissible = true,
  Future<bool> Function()? onConfirmed,
}) {
  return _showConfirmationDialog(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    barrierDismissible: barrierDismissible,
    onConfirmed: onConfirmed,
    isDestructive: false,
  );
}

Future<bool?> _showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  required bool barrierDismissible,
  Future<bool> Function()? onConfirmed,
  required bool isDestructive,
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
          confirmLabel:
              confirmLabel ?? (isDestructive ? l10n.delete : l10n.ai_confirm),
          cancelLabel: cancelLabel ?? l10n.cancel,
          isDark: isDark,
          onConfirmed: onConfirmed,
          isDestructive: isDestructive,
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
    this.isDestructive = true,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDark;
  final Future<bool> Function()? onConfirmed;
  final bool isDestructive;

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

  Widget _buildConfirmButton(
    BuildContext context, {
    required TextTheme textTheme,
    required double buttonFontSize,
  }) {
    final confirmChild =
        _isLoading
            ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color:
                    widget.isDestructive
                        ? Colors.red.shade600
                        : (widget.isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryDark),
              ),
            )
            : Text(
              widget.confirmLabel,
              textAlign: TextAlign.center,
              strutStyle: context.tibetanStrutStyle(
                buttonFontSize,
                compact: true,
              ),
              style: textTheme.labelLarge?.copyWith(
                fontSize: buttonFontSize,
                fontWeight:
                    widget.isDestructive ? FontWeight.normal : FontWeight.w600,
                color:
                    widget.isDestructive
                        ? AppColors.danger
                        : (widget.isDark ? AppColors.danger : AppColors.danger),
              ),
            );

    if (widget.isDestructive) {
      return OutlinedButton(
        onPressed: _isLoading ? null : _handleConfirm,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade600,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          side: const BorderSide(color: AppColors.grey300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: confirmChild,
      );
    }

    return FilledButton(
      onPressed: _isLoading ? null : _handleConfirm,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.danger,
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(
          color: widget.isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      child: confirmChild,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const titleFontSize = 18.0;
    const messageFontSize = 14.0;
    const buttonFontSize = 15.0;

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
                strutStyle: context.tibetanStrutStyle(titleFontSize),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: titleFontSize,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.message,
                strutStyle: context.tibetanStrutStyle(messageFontSize),
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: messageFontSize,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _buildConfirmButton(
                  context,
                  textTheme: textTheme,
                  buttonFontSize: buttonFontSize,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        widget.isDark
                            ? AppColors.textPrimaryDark
                            : Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    side: const BorderSide(color: AppColors.grey300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    widget.cancelLabel,
                    textAlign: TextAlign.center,
                    strutStyle: context.tibetanStrutStyle(
                      buttonFontSize,
                      compact: true,
                    ),
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: buttonFontSize,
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
