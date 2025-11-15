import 'package:flutter/material.dart';

/// A widget that displays a section of recitation text.
///
/// This widget handles:
/// - Replacing HTML break tags with newlines
/// - Applying consistent text styling
/// - Proper text rendering with appropriate line height
class RecitationTextSection extends StatelessWidget {
  /// The text content to display
  final String text;

  const RecitationTextSection({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // Replace HTML break tags with newlines
    final processedText = _processText(text);

    return Text(
      processedText,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.8,
            fontSize: 16,
          ),
    );
  }

  /// Processes the text by replacing HTML break tags with newlines.
  ///
  /// Handles both <br> and <br/> tags.
  String _processText(String text) {
    return text
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n');
  }
}
