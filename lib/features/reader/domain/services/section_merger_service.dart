import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_item.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/domain/services/section_flattener_service.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';

/// Service responsible for efficiently merging new sections into existing
/// flattened content during pagination
class SectionMergerService {
  final SectionFlattenerService _flattener;
  final _logger = AppLogger('SectionMergerService');

  SectionMergerService({
    SectionFlattenerService? flattener,
  }) : _flattener = flattener ?? const SectionFlattenerService();

  /// Merges new sections into existing flattened content
  /// 
  /// Uses Set-based deduplication for O(1) duplicate detection.
  /// 
  /// [existing] - The current flattened content
  /// [newSections] - New sections to merge in
  /// [direction] - Whether to prepend (previous) or append (next)
  /// 
  /// Returns a new FlattenedContent with merged items and updated index map
  FlattenedContent merge(
    FlattenedContent existing,
    List<Section> newSections,
    PaginationDirection direction,
  ) {
    if (newSections.isEmpty) {
      return existing;
    }

    if (existing.isEmpty) {
      return _flattener.flatten(newSections);
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Create a Set of existing segment IDs for O(1) lookup
      final existingSegmentIds = existing.segmentIndexMap.keys.toSet();
      
      // Create a Set of existing section IDs to track headers
      final existingSectionIds = <String>{};
      for (final item in existing.items) {
        if (item.isHeader && item.section != null) {
          existingSectionIds.add(item.section!.id);
        }
      }

      // Flatten the new sections
      final newFlattened = _flattener.flatten(newSections);

      // Filter out items that already exist
      final newItems = <FlattenedItem>[];
      for (final item in newFlattened.items) {
        if (item.isSegment) {
          // Only add segment if it doesn't already exist
          if (!existingSegmentIds.contains(item.segmentId)) {
            newItems.add(item);
          }
        } else if (item.isHeader) {
          // Only add header if the section doesn't already exist
          if (!existingSectionIds.contains(item.section!.id)) {
            newItems.add(item);
          }
        }
      }

      if (newItems.isEmpty) {
        _logger.debug('No new items to merge (all duplicates)');
        return existing;
      }

      // Merge based on direction
      final List<FlattenedItem> mergedItems;
      if (direction == PaginationDirection.previous) {
        // Prepend new items to existing
        mergedItems = [...newItems, ...existing.items];
      } else {
        // Append new items to existing
        mergedItems = [...existing.items, ...newItems];
      }

      // Rebuild the index map in a single pass
      final newIndexMap = _rebuildIndexMap(mergedItems);

      // Count total segments
      final totalSegments = newIndexMap.length;

      stopwatch.stop();
      _logger.debug(
        'Merged ${newItems.length} items (${direction.name}) in ${stopwatch.elapsedMilliseconds}ms. '
        'Total items: ${mergedItems.length}, Total segments: $totalSegments',
      );

      return FlattenedContent(
        items: mergedItems,
        segmentIndexMap: newIndexMap,
        totalSegments: totalSegments,
      );
    } catch (e, stackTrace) {
      _logger.error('Error merging sections', e, stackTrace);
      // Return existing content on error to avoid breaking the UI
      return existing;
    }
  }

  /// Rebuilds the segment index map from a list of items
  /// This is O(n) where n is the number of items
  Map<String, int> _rebuildIndexMap(List<FlattenedItem> items) {
    final indexMap = <String, int>{};
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.isSegment && item.segmentId != null) {
        indexMap[item.segmentId!] = i;
      }
    }
    return indexMap;
  }

  /// Merges raw sections using the legacy approach (for compatibility)
  /// This is useful when working with the original Section models before flattening
  List<Section> mergeRawSections(
    List<Section> existingSections,
    List<Section> newSections,
    PaginationDirection direction,
  ) {
    if (existingSections.isEmpty) return newSections;
    if (newSections.isEmpty) return existingSections;

    final mergedSections = List<Section>.from(existingSections);

    try {
      for (final newSection in newSections) {
        final existingIndex = mergedSections.indexWhere(
          (section) => section.id == newSection.id,
        );

        if (existingIndex != -1) {
          // Section exists, merge segments
          final existingSection = mergedSections[existingIndex];
          final existingSegmentIds =
              existingSection.segments.map((s) => s.segmentId).toSet();

          final newSegments = <Segment>[];
          for (final segment in newSection.segments) {
            if (!existingSegmentIds.contains(segment.segmentId)) {
              newSegments.add(segment);
            }
          }

          if (newSegments.isNotEmpty) {
            final List<Segment> mergedSegments =
                direction == PaginationDirection.previous
                    ? [...newSegments, ...existingSection.segments]
                    : [...existingSection.segments, ...newSegments];

            // Merge nested sections recursively
            final mergedNestedSections = mergeRawSections(
              existingSection.sections ?? [],
              newSection.sections ?? [],
              direction,
            );

            mergedSections[existingIndex] = existingSection.copyWith(
              segments: mergedSegments,
              sections: mergedNestedSections,
            );
          }
        } else {
          // Section doesn't exist, add it
          if (direction == PaginationDirection.previous) {
            mergedSections.insert(0, newSection);
          } else {
            mergedSections.add(newSection);
          }
        }
      }
    } catch (e) {
      _logger.error('Error merging raw sections', e);
    }

    return mergedSections;
  }
}
