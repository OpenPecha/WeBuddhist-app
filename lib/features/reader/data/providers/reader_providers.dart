import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

// Re-export the main notifier
export 'package:flutter_pecha/features/reader/data/providers/reader_notifier.dart';

/// Provider for ItemScrollController - used for programmatic scrolling
/// This is scoped to the reader widget tree
final readerScrollControllerProvider = Provider.autoDispose<ItemScrollController>(
  (ref) => ItemScrollController(),
);

/// Provider for ItemPositionsListener - used for tracking visible items
final readerPositionsListenerProvider = Provider.autoDispose<ItemPositionsListener>(
  (ref) => ItemPositionsListener.create(),
);

/// Provider for tracking if scroll-to-segment is in progress
final isScrollingToSegmentProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// Provider for tracking the target segment to scroll to after content loads
final pendingScrollTargetProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
