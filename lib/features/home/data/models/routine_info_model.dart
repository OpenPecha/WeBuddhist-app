import 'package:flutter_pecha/features/home/domain/entities/routine_info.dart';

class RoutineInfoModel {
  final int seriesCount;
  final int recitationCount;

  const RoutineInfoModel({
    required this.seriesCount,
    required this.recitationCount,
  });

  factory RoutineInfoModel.fromJson(Map<String, dynamic> json) {
    return RoutineInfoModel(
      seriesCount: (json['series_count'] as num?)?.toInt() ?? 0,
      recitationCount: (json['recitation_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'series_count': seriesCount, 'recitation_count': recitationCount};
  }

  RoutineInfo toEntity() {
    return RoutineInfo(
      seriesCount: seriesCount,
      recitationCount: recitationCount,
    );
  }
}
