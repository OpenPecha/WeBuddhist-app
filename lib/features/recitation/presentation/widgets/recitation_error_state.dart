import 'package:flutter/material.dart';

/// A widget that displays an error state for recitation loading failures.
///
/// This widget provides a user-friendly error display with:
/// - An error icon
/// - A descriptive error message
/// - The error details (for debugging)
class RecitationErrorState extends StatelessWidget {
  /// The error object to display
  final Object error;

  const RecitationErrorState({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),

            // Error title
            Text(
              'Failed to load recitation',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Error details
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
