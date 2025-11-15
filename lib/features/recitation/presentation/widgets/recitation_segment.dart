import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_content_model.dart';
import 'package:flutter_pecha/features/recitation/domain/content_type.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_text_section.dart';

/// A widget that displays a single segment of recitation content.
///
/// This widget handles the rendering of different content types
/// (recitation, translation, transliteration, adaptation) based on
/// the specified display order.
class RecitationSegment extends StatelessWidget {
  /// The segment data to display
  final RecitationSegmentModel segment;

  /// The order in which to display different content types
  final List<ContentType> contentOrder;

  /// Whether this is the first segment (affects divider display)
  final bool isFirstSegment;

  const RecitationSegment({
    super.key,
    required this.segment,
    required this.contentOrder,
    this.isFirstSegment = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add divider for segments after the first one
        if (!isFirstSegment) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
        ],

        // Render content in the specified order
        ...contentOrder.expand((contentType) {
          return _buildContentForType(contentType);
        }),
      ],
    );
  }

  /// Builds the widgets for a specific content type.
  ///
  /// Returns an empty list if the content type is not available
  /// in this segment.
  List<Widget> _buildContentForType(ContentType contentType) {
    final Map<String, RecitationTextModel>? contentMap;

    switch (contentType) {
      case ContentType.recitation:
        contentMap = segment.recitation;
        break;
      case ContentType.translation:
        contentMap = segment.translations;
        break;
      case ContentType.transliteration:
        contentMap = segment.transliterations;
        break;
      case ContentType.adaptation:
        contentMap = segment.adaptations;
        break;
    }

    // Return empty list if this content type is not available
    if (contentMap == null || contentMap.isEmpty) {
      return [];
    }

    // Build widgets for each text entry
    final widgets = <Widget>[];
    bool isFirstEntry = true;

    for (final entry in contentMap.entries) {
      // Add spacing between different entries (but not before the first one)
      if (!isFirstEntry) {
        widgets.add(const SizedBox(height: 8));
      }
      isFirstEntry = false;

      widgets.add(RecitationTextSection(text: entry.value.content));
    }

    return widgets;
  }
}
