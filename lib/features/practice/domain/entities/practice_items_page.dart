import 'package:flutter_pecha/features/practice/domain/entities/practice_item.dart';

/// One page of practice items returned by `GET /practice/items`.
///
/// Uses 1-based page indexing to match the backend contract; `hasMore` is
/// derived from `page < totalPages` so callers do not have to reason about
/// the underlying numbers.
class PracticeItemsPage {
  final List<PracticeItem> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const PracticeItemsPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}
