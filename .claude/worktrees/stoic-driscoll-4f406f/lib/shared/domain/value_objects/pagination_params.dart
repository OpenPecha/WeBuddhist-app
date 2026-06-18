import 'package:flutter_pecha/shared/domain/entities/value_object.dart';

/// Pagination parameters value object.
///
/// Encapsulates pagination configuration.
class PaginationParams extends ValueObject {
  final int page;
  final int limit;

  const PaginationParams({
    this.page = 1,
    this.limit = 20,
  }) : assert(page > 0, 'Page must be greater than 0'),
       assert(limit > 0, 'Limit must be greater than 0'),
       assert(limit <= 100, 'Limit must not exceed 100');

  /// Calculate offset for database queries.
  int get offset => (page - 1) * limit;

  /// Create params for the next page.
  PaginationParams nextPage() {
    return PaginationParams(page: page + 1, limit: limit);
  }

  /// Create params for the previous page.
  PaginationParams? previousPage() {
    if (page <= 1) return null;
    return PaginationParams(page: page - 1, limit: limit);
  }

  @override
  List<Object?> get props => [page, limit];

  /// Create from JSON.
  factory PaginationParams.fromJson(Map<String, dynamic> json) {
    return PaginationParams(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
    };
  }
}
