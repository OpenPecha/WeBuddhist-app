/// Wire-level type discriminator for the `/practice/items` response.
enum PracticeItemType {
  plan,
  series,
  unknown;

  static PracticeItemType fromJson(String? value) => switch (value) {
    'plan' => PracticeItemType.plan,
    'series' => PracticeItemType.series,
    _ => PracticeItemType.unknown,
  };
}

/// One row of `GET /practice/items`. The backend returns a single item shape
/// discriminated by [type]: a `plan` row has plan fields at the top level,
/// while a `series` row carries series metadata + nested plans.
///
/// Parsing keeps the raw JSON around so the repository can lazily convert to
/// the right domain entity ([PlansModel] / [SeriesModel]) based on [type].
class PracticeItemModel {
  final String id;
  final PracticeItemType type;
  final Map<String, dynamic> raw;

  const PracticeItemModel({
    required this.id,
    required this.type,
    required this.raw,
  });

  factory PracticeItemModel.fromJson(Map<String, dynamic> json) {
    return PracticeItemModel(
      id: (json['id'] as String?) ?? '',
      type: PracticeItemType.fromJson(json['type'] as String?),
      raw: json,
    );
  }
}

/// Page metadata for `GET /practice/items`.
class PracticePaginationModel {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const PracticePaginationModel({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory PracticePaginationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PracticePaginationModel(
        page: 1,
        pageSize: 0,
        total: 0,
        totalPages: 1,
      );
    }
    return PracticePaginationModel(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Full response envelope for `GET /practice/items`.
class PracticeItemsResponseModel {
  final List<PracticeItemModel> items;
  final PracticePaginationModel pagination;

  const PracticeItemsResponseModel({
    required this.items,
    required this.pagination,
  });

  factory PracticeItemsResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const [];
    return PracticeItemsResponseModel(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PracticeItemModel.fromJson)
          .toList(),
      pagination: PracticePaginationModel.fromJson(
        json['pagination'] as Map<String, dynamic>?,
      ),
    );
  }
}
