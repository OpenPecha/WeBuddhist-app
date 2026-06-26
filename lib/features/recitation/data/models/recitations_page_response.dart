import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';

class RecitationsPageResponse {
  final List<RecitationModel> recitations;
  final int skip;
  final int limit;
  final int total;

  const RecitationsPageResponse({
    required this.recitations,
    required this.skip,
    required this.limit,
    required this.total,
  });

  factory RecitationsPageResponse.fromJson(Map<String, dynamic> json) {
    final recitationsData = json['recitations'] as List<dynamic>? ?? [];
    return RecitationsPageResponse(
      recitations:
          recitationsData
              .map(
                (item) =>
                    RecitationModel.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      skip: json['skip'] as int? ?? 0,
      limit: json['limit'] as int? ?? recitationsData.length,
      total: json['total'] as int? ?? recitationsData.length,
    );
  }

  bool get hasMore => skip + recitations.length < total;
}
