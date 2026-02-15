import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_item.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/data/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/data/providers/reader_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/section_header.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_item.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_skeleton.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Main content widget for the reader
/// Uses ScrollablePositionedList for efficient rendering and scrolling
class ReaderContentPart extends ConsumerStatefulWidget {
  final ReaderParams params;
  final String language;
  final String? initialSegmentId;
  final void Function(bool isScrollingDown)? onScrollDirectionChanged;

  const ReaderContentPart({
    super.key,
    required this.params,
    required this.language,
    this.initialSegmentId,
    this.onScrollDirectionChanged,
  });

  @override
  ConsumerState<ReaderContentPart> createState() => _ReaderContentPartState();
}

class _ReaderContentPartState extends ConsumerState<ReaderContentPart> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final _logger = AppLogger('ReaderContent');

  Timer? _debounceTimer;
  bool _hasTriggeredPrevious = false;
  bool _hasTriggeredNext = false;
  bool _hasScrolledToInitial = false;
  int? _positionBeforePreviousLoad;

  // Scroll direction tracking
  double _lastScrollOffset = 0;
  bool _lastScrollDirection = false; // false = up, true = down

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_onScrollPositionChanged);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(
      _onScrollPositionChanged,
    );
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScrollPositionChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(ReaderConstants.scrollDebounce, () {
      _checkPaginationThresholds();
    });

    // Track scroll direction for app bar visibility
    _trackScrollDirection();
  }

  void _trackScrollDirection() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Calculate approximate scroll offset based on first visible item
    final sortedPositions =
        positions.toList()..sort((a, b) => a.index.compareTo(b.index));
    final firstItem = sortedPositions.first;
    final currentOffset = firstItem.index + (1 - firstItem.itemLeadingEdge);

    // Determine scroll direction with a small threshold to avoid jitter
    const threshold = 0.5;
    if ((currentOffset - _lastScrollOffset).abs() > threshold) {
      final isScrollingDown = currentOffset > _lastScrollOffset;
      if (isScrollingDown != _lastScrollDirection) {
        _lastScrollDirection = isScrollingDown;
        widget.onScrollDirectionChanged?.call(isScrollingDown);
      }
      _lastScrollOffset = currentOffset;
    }
  }

  void _checkPaginationThresholds() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final sortedPositions =
        positions.toList()..sort((a, b) => a.index.compareTo(b.index));
    final firstVisibleIndex = sortedPositions.first.index;
    final lastVisibleIndex = sortedPositions.last.index;

    final state = ref.read(readerNotifierProvider(widget.params));
    final notifier = ref.read(readerNotifierProvider(widget.params).notifier);
    final totalItems = state.content?.itemCount ?? 0;

    // Check for previous page load
    if (firstVisibleIndex <= ReaderConstants.previousLoadThreshold &&
        state.hasPreviousPage &&
        !state.isLoadingPrevious &&
        !_hasTriggeredPrevious) {
      _hasTriggeredPrevious = true;
      _positionBeforePreviousLoad = firstVisibleIndex;
      _logger.debug(
        'Triggering previous page load at index $firstVisibleIndex',
      );
      notifier.loadPreviousPage().then((_) {
        _hasTriggeredPrevious = false;
        _adjustScrollAfterPreviousLoad();
      });
    }

    // Check for next page load
    if (lastVisibleIndex >= totalItems - ReaderConstants.nextLoadThreshold &&
        state.hasNextPage &&
        !state.isLoadingNext &&
        !_hasTriggeredNext) {
      _hasTriggeredNext = true;
      _logger.debug(
        'Triggering next page load at index $lastVisibleIndex/$totalItems',
      );
      notifier.loadNextPage().then((_) {
        _hasTriggeredNext = false;
      });
    }
  }

  void _adjustScrollAfterPreviousLoad() {
    if (_positionBeforePreviousLoad == null) return;

    final state = ref.read(readerNotifierProvider(widget.params));
    final content = state.content;
    if (content == null) return;

    // Calculate how many items were added at the beginning
    // This is approximate - we adjust based on the position we were at
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemScrollController.isAttached &&
          _positionBeforePreviousLoad != null) {
        // Estimate the number of new items added
        // For simplicity, we'll use the page size as an approximation
        final newItemsCount = ReaderConstants.pageSize;
        final targetIndex = _positionBeforePreviousLoad! + newItemsCount;

        if (targetIndex >= 0 && targetIndex < content.itemCount) {
          _itemScrollController.jumpTo(index: targetIndex);
          _logger.debug(
            'Adjusted scroll after prepend: $targetIndex (added ~$newItemsCount items)',
          );
        }
      }
      _positionBeforePreviousLoad = null;
    });
  }

  void _scrollToSegment(String segmentId, FlattenedContent content) {
    final index = content.getSegmentIndex(segmentId);
    if (index == null) {
      _logger.debug('Segment $segmentId not found in content');
      return;
    }

    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: ReaderConstants.scrollAnimationDuration,
        curve: Curves.easeInOutCubic,
        alignment: ReaderConstants.scrollToSegmentAlignment,
      );
      _logger.debug('Scrolling to segment $segmentId at index $index');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerNotifierProvider(widget.params));
    final notifier = ref.read(readerNotifierProvider(widget.params).notifier);

    // Handle initial scroll to segment
    if (!_hasScrolledToInitial &&
        state.content != null &&
        state.content!.isNotEmpty &&
        widget.initialSegmentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasScrolledToInitial && _itemScrollController.isAttached) {
          _scrollToSegment(widget.initialSegmentId!, state.content!);
          _hasScrolledToInitial = true;
        }
      });
    }

    final content = state.content;
    if (content == null || content.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Loading previous indicator
        if (state.isLoadingPrevious)
          const PaginationLoadingIndicator(
            message: 'Loading previous...',
            showSkeleton: true,
          ),

        // Main content list
        Expanded(
          child: ScrollablePositionedList.builder(
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            itemCount: content.itemCount,
            padding: const EdgeInsets.only(bottom: 40),
            itemBuilder: (context, index) {
              final item = content.getItemAt(index);
              if (item == null) return const SizedBox.shrink();

              return _buildItem(
                item: item,
                state: state,
                onSegmentTap:
                    (segment) => notifier.toggleSegmentSelection(segment),
              );
            },
          ),
        ),

        // Loading next indicator
        if (state.isLoadingNext)
          const PaginationLoadingIndicator(
            message: 'Loading more...',
            showSkeleton: true,
          ),
      ],
    );
  }

  Widget _buildItem({
    required FlattenedItem item,
    required ReaderState state,
    required void Function(Segment) onSegmentTap,
  }) {
    return item.when(
      header:
          (section, depth) {
            // Only show section headers for nested sections (depth > 0)
            // The chapter header (depth 0) is shown at the top of the screen
            if (depth == 0) {
              return const SizedBox.shrink();
            }
            return SectionHeader(
              section: section,
              depth: depth,
              language: widget.language,
            );
          },
      segment:
          (segment, depth, sectionId) => SegmentItem(
            segment: segment,
            depth: depth,
            language: widget.language,
            isSelected: state.selectedSegment?.segmentId == segment.segmentId,
            isHighlighted: state.highlightedSegmentId == segment.segmentId,
            highlightSource: state.highlightSource,
            onTap: () => onSegmentTap(segment),
          ),
    );
  }
}
