import 'package:flutter_pecha/features/plans/models/plans_model.dart';

class PlanListResponseModel {
  final List<PlansModel> plans;
  final int total;
  final int skip;
  final int limit;

  PlanListResponseModel({
    required this.plans,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory PlanListResponseModel.fromJson(Map<String, dynamic> json) {
    return PlanListResponseModel(
      plans:
          (json['plans'] as List).map((e) => PlansModel.fromJson(e)).toList(),
      total: json['total'] as int,
      skip: json['skip'] as int,
      limit: json['limit'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plans': plans.map((e) => e.toJson()).toList(),
      'total': total,
      'skip': skip,
      'limit': limit,
    };
  }
}
