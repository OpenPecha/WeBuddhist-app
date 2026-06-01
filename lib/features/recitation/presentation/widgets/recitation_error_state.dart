import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';

/// A widget that displays an error state for recitation loading failures.
///
/// This is a wrapper around the generic ErrorStateWidget with recitation-specific messaging.
class RecitationErrorState extends StatelessWidget {
  /// The error object to display
  final Object error;

  /// Optional callback for retry action
  final VoidCallback? onRetry;

  const RecitationErrorState({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      error: error,
      onRetry: onRetry,
      customMessage: _getRecitationSpecificMessage(context, error.toString()),
    );
  }

  /// Returns recitation-specific error messages for known error types
  String? _getRecitationSpecificMessage(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;
    if (error.contains('404')) {
      return l10n.recitation_unavailable;
    } else if (error.contains('401')) {
      return l10n.recitation_sign_in_required;
    }
    return ErrorStateWidget(error: error, onRetry: onRetry).customMessage;
  }
}
