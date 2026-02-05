import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';

/// Type of flattened item
enum FlattenedItemType {
  header,
  segment,
}

/// Represents a flattened item in the reader list
/// Can be either a section header or a segment
class FlattenedItem {
  final FlattenedItemType type;
  final Section? section;
  final Segment? segment;
  final int depth;
  final String? sectionId;

  const FlattenedItem._({
    required this.type,
    this.section,
    this.segment,
    required this.depth,
    this.sectionId,
  });

  /// Creates a header item for a section
  factory FlattenedItem.header({
    required Section section,
    required int depth,
  }) {
    return FlattenedItem._(
      type: FlattenedItemType.header,
      section: section,
      depth: depth,
    );
  }

  /// Creates a segment item
  factory FlattenedItem.segment({
    required Segment segment,
    required int depth,
    required String sectionId,
  }) {
    return FlattenedItem._(
      type: FlattenedItemType.segment,
      segment: segment,
      depth: depth,
      sectionId: sectionId,
    );
  }

  /// Check if this is a header item
  bool get isHeader => type == FlattenedItemType.header;

  /// Check if this is a segment item
  bool get isSegment => type == FlattenedItemType.segment;

  /// Get the segment ID if this is a segment item
  String? get segmentId => segment?.segmentId;

  /// Get the title if this is a header item
  String? get title => section?.title;

  /// Pattern matching helper for when syntax
  T when<T>({
    required T Function(Section section, int depth) header,
    required T Function(Segment segment, int depth, String sectionId) segment,
  }) {
    switch (type) {
      case FlattenedItemType.header:
        return header(section!, depth);
      case FlattenedItemType.segment:
        return segment(this.segment!, depth, sectionId!);
    }
  }

  /// Pattern matching helper for maybeWhen syntax
  T maybeWhen<T>({
    T Function(Section section, int depth)? header,
    T Function(Segment segment, int depth, String sectionId)? segment,
    required T Function() orElse,
  }) {
    switch (type) {
      case FlattenedItemType.header:
        return header != null ? header(section!, depth) : orElse();
      case FlattenedItemType.segment:
        return segment != null
            ? segment(this.segment!, depth, sectionId!)
            : orElse();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlattenedItem &&
        other.type == type &&
        other.section?.id == section?.id &&
        other.segment?.segmentId == segment?.segmentId &&
        other.depth == depth;
  }

  @override
  int get hashCode => Object.hash(
    type,
    section?.id,
    segment?.segmentId,
    depth,
  );

  @override
  String toString() {
    return type == FlattenedItemType.header
        ? 'FlattenedItem.header(section: ${section?.id}, depth: $depth)'
        : 'FlattenedItem.segment(segmentId: ${segment?.segmentId}, depth: $depth)';
  }
}
