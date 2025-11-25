import 'package:flutter_pecha/features/plans/models/user/user_plans_model.dart';

class UserPlanListResponseModel {
  final List<UserPlansModel> userPlans;
  final int total;
  final int skip;
  final int limit;

  UserPlanListResponseModel({
    required this.userPlans,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory UserPlanListResponseModel.fromJson(Map<String, dynamic> json) {
    return UserPlanListResponseModel(
      userPlans:
          (json['plans'] as List)
              .map((e) => UserPlansModel.fromJson(e))
              .toList(),
      total: json['total'] as int,
      skip: json['skip'] as int,
      limit: json['limit'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plans': userPlans.map((e) => e.toJson()).toList(),
      'total': total,
      'skip': skip,
      'limit': limit,
    };
  }
}
