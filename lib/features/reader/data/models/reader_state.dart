import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_pecha/features/texts/models/text_detail.dart';

/// Status of the reader
enum ReaderStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Direction for pagination
enum PaginationDirection {
  next,
  previous,
}

/// Main state model for the reader feature
class ReaderState {
  // Core content
  final String textId;
  final String? contentId;
  final TextDetail? textDetail;
  final FlattenedContent? content;

  // Navigation context
  final NavigationContext? navigationContext;

  // Selection
  final Segment? selectedSegment;

  // Commentary
  final String? commentarySegmentId;
  final double splitRatio;

  // Highlight (auto-clears after animation)
  final String? highlightedSegmentId;
  final NavigationSource highlightSource;

  // Loading states
  final ReaderStatus status;
  final bool isLoadingNext;
  final bool isLoadingPrevious;
  final String? errorMessage;

  // Pagination info
  final int currentSegmentPosition;
  final int totalSegments;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const ReaderState({
    required this.textId,
    this.contentId,
    this.textDetail,
    this.content,
    this.navigationContext,
    this.selectedSegment,
    this.commentarySegmentId,
    this.splitRatio = 0.5,
    this.highlightedSegmentId,
    this.highlightSource = NavigationSource.normal,
    this.status = ReaderStatus.initial,
    this.isLoadingNext = false,
    this.isLoadingPrevious = false,
    this.errorMessage,
    this.currentSegmentPosition = 1,
    this.totalSegments = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
  });

  /// Creates an initial state for a text
  factory ReaderState.initial(String textId) {
    return ReaderState(textId: textId);
  }

  /// Check if the reader is in a loading state
  bool get isLoading => status == ReaderStatus.loading;

  /// Check if the reader is in an error state
  bool get isError => status == ReaderStatus.error;

  /// Check if the reader has loaded content
  bool get hasContent => content != null && content!.isNotEmpty;

  /// Check if commentary panel is open
  bool get isCommentaryOpen => commentarySegmentId != null;

  /// Check if a segment is selected
  bool get hasSelection => selectedSegment != null;

  /// Check if a segment is highlighted
  bool get hasHighlight => highlightedSegmentId != null;

  /// Check if swipe navigation is available
  bool get canSwipe => navigationContext?.canSwipe ?? false;

  ReaderState copyWith({
    String? textId,
    String? contentId,
    TextDetail? textDetail,
    FlattenedContent? content,
    NavigationContext? navigationContext,
    Segment? selectedSegment,
    String? commentarySegmentId,
    double? splitRatio,
    String? highlightedSegmentId,
    NavigationSource? highlightSource,
    ReaderStatus? status,
    bool? isLoadingNext,
    bool? isLoadingPrevious,
    String? errorMessage,
    int? currentSegmentPosition,
    int? totalSegments,
    bool? hasNextPage,
    bool? hasPreviousPage,
    // Special flags for clearing nullable fields
    bool clearSelectedSegment = false,
    bool clearCommentarySegmentId = false,
    bool clearHighlightedSegmentId = false,
    bool clearErrorMessage = false,
  }) {
    return ReaderState(
      textId: textId ?? this.textId,
      contentId: contentId ?? this.contentId,
      textDetail: textDetail ?? this.textDetail,
      content: content ?? this.content,
      navigationContext: navigationContext ?? this.navigationContext,
      selectedSegment:
          clearSelectedSegment ? null : (selectedSegment ?? this.selectedSegment),
      commentarySegmentId:
          clearCommentarySegmentId
              ? null
              : (commentarySegmentId ?? this.commentarySegmentId),
      splitRatio: splitRatio ?? this.splitRatio,
      highlightedSegmentId:
          clearHighlightedSegmentId
              ? null
              : (highlightedSegmentId ?? this.highlightedSegmentId),
      highlightSource: highlightSource ?? this.highlightSource,
      status: status ?? this.status,
      isLoadingNext: isLoadingNext ?? this.isLoadingNext,
      isLoadingPrevious: isLoadingPrevious ?? this.isLoadingPrevious,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      currentSegmentPosition:
          currentSegmentPosition ?? this.currentSegmentPosition,
      totalSegments: totalSegments ?? this.totalSegments,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderState &&
        other.textId == textId &&
        other.contentId == contentId &&
        other.status == status &&
        other.selectedSegment?.segmentId == selectedSegment?.segmentId &&
        other.highlightedSegmentId == highlightedSegmentId;
  }

  @override
  int get hashCode => Object.hash(
    textId,
    contentId,
    status,
    selectedSegment?.segmentId,
    highlightedSegmentId,
  );

  @override
  String toString() {
    return 'ReaderState(textId: $textId, status: $status, segments: ${content?.totalSegments ?? 0})';
  }
}
