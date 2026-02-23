import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_item.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';

/// Service responsible for flattening nested sections into a single list
/// with O(1) segment lookups via an index map
class SectionFlattenerService {
  const SectionFlattenerService();

  /// Flattens a list of sections into a FlattenedContent
  /// 
  /// This converts the hierarchical section/segment structure into a flat list
  /// suitable for use with ListView.builder, while maintaining a map for O(1)
  /// segment index lookups.
  /// 
  /// The flattening preserves the order: section header, then segments,
  /// then nested sections recursively.
  FlattenedContent flatten(List<Section> sections) {
    final items = <FlattenedItem>[];
    final indexMap = <String, int>{};
    int segmentCount = 0;

    void processSection(Section section, int depth) {
      // Add section header
      items.add(FlattenedItem.header(
        section: section,
        depth: depth,
      ));

      // Add direct segments
      for (final segment in section.segments) {
        // Store the index before adding the item
        indexMap[segment.segmentId] = items.length;
        items.add(FlattenedItem.segment(
          segment: segment,
          depth: depth,
          sectionId: section.id,
        ));
        segmentCount++;
      }

      // Process nested sections recursively
      if (section.sections != null) {
        for (final nestedSection in section.sections!) {
          processSection(nestedSection, depth + 1);
        }
      }
    }

    // Process all top-level sections
    for (final section in sections) {
      processSection(section, 0);
    }

    return FlattenedContent(
      items: items,
      segmentIndexMap: indexMap,
      totalSegments: segmentCount,
    );
  }

  /// Gets the total count of items that would be in the flattened list
  /// without actually flattening (useful for validation)
  int calculateItemCount(List<Section> sections) {
    int count = 0;

    void countSection(Section section) {
      count++; // Section header
      count += section.segments.length; // Direct segments

      if (section.sections != null) {
        for (final nestedSection in section.sections!) {
          countSection(nestedSection);
        }
      }
    }

    for (final section in sections) {
      countSection(section);
    }

    return count;
  }

  /// Gets the total count of segments only (not including headers)
  int calculateSegmentCount(List<Section> sections) {
    int count = 0;

    void countSegments(Section section) {
      count += section.segments.length;

      if (section.sections != null) {
        for (final nestedSection in section.sections!) {
          countSegments(nestedSection);
        }
      }
    }

    for (final section in sections) {
      countSegments(section);
    }

    return count;
  }
}
