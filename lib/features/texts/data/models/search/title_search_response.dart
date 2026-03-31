/// Model for a single title search result item
class TitleSearchItem {
  final String id;
  final String title;

  TitleSearchItem({
    required this.id,
    required this.title,
  });

  factory TitleSearchItem.fromJson(Map<String, dynamic> json) {
    return TitleSearchItem(
      id: json['id'] as String,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}

/// Response model for title search API
class TitleSearchResponse {
  final List<TitleSearchItem> results;
  final int total;
  final int limit;
  final int offset;

  TitleSearchResponse({
    required this.results,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory TitleSearchResponse.fromJson(List<dynamic> json, {
    int? total,
    int? limit,
    int? offset,
  }) {
    return TitleSearchResponse(
      results: json
          .map((e) => TitleSearchItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: total ?? json.length,
      limit: limit ?? 20,
      offset: offset ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.map((e) => e.toJson()).toList(),
      'total': total,
      'limit': limit,
      'offset': offset,
    };
  }

  /// Check if there are more results available
  bool get hasMore => offset + results.length < total;

  /// Check if response is empty
  bool get isEmpty => results.isEmpty;

  /// Check if response has results
  bool get isNotEmpty => results.isNotEmpty;
}
