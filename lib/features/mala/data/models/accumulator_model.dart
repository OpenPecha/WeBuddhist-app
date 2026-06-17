import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';

/// Maps the API's accumulator DTOs — both `PublicAccumulatorDTO`
/// (`GET /accumulators`, presets) and `AccumulatorDTO`
/// (`GET/POST/PUT /accumulators/user`, the user's own).
class AccumulatorModel {
  const AccumulatorModel({
    required this.id,
    this.userId,
    this.type,
    required this.name,
    this.description,
    this.targetCount,
    this.currentCount = 0,
    this.textId,
    this.mantraId,
    this.beadImageUrl,
    this.updatedAt,
  });

  final String id;
  final String? userId;
  final String? type;
  final String name;
  final String? description;
  final int? targetCount;
  final int currentCount;
  final String? textId;
  final String? mantraId;

  /// Bead artwork URL — the backend will add this to `GET /accumulators`.
  /// Read defensively across likely key names until the contract is final.
  final String? beadImageUrl;
  final DateTime? updatedAt;

  factory AccumulatorModel.fromJson(Map<String, dynamic> json) {
    return AccumulatorModel(
      id: (json['id'] as String?) ?? '',
      userId: json['user_id'] as String?,
      type: json['type'] as String?,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      targetCount: (json['target_count'] as num?)?.toInt(),
      currentCount: (json['current_count'] as num?)?.toInt() ?? 0,
      textId: json['text_id'] as String?,
      mantraId: json['mantra_id'] as String?,
      beadImageUrl: (json['bead_image_url'] ??
          json['bead_image'] ??
          json['image_url']) as String?,
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  MalaCount toMalaCount() => MalaCount(
        accumulatorId: id,
        mantraId: mantraId,
        total: currentCount,
        updatedAt: updatedAt,
      );

  static DateTime? _parseDate(Object? v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}

/// Wrapper for the paginated accumulator list responses
/// (`PublicAccumulatorsResponse` / `AccumulatorsResponse`).
class AccumulatorsResponseModel {
  const AccumulatorsResponseModel({
    required this.accumulators,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<AccumulatorModel> accumulators;
  final int total;
  final int skip;
  final int limit;

  factory AccumulatorsResponseModel.fromJson(Map<String, dynamic> json) {
    final list = (json['accumulators'] as List<dynamic>?) ?? [];
    return AccumulatorsResponseModel(
      accumulators: list
          .map((e) => AccumulatorModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? list.length,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? list.length,
    );
  }
}
