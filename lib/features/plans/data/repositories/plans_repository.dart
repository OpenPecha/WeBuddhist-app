import 'package:flutter_pecha/features/plans/models/plans_model.dart';

import '../datasource/plans_remote_datasource.dart';

class PlansRepository {
  final PlansRemoteDatasource plansRemoteDatasource;

  PlansRepository({required this.plansRemoteDatasource});

  Future<List<PlansModel>> getPlans({
    required String language,
    String? search,
    String? tag,
    int? skip,
    int? limit,
  }) async {
    try {
      return await plansRemoteDatasource.fetchPlans(
        queryParams: PlansQueryParams(
          language: language,
          search: search,
          tag: tag,
          skip: skip,
          limit: limit,
        ),
      );
    } catch (e) {
      throw Exception('Failed to load plans: $e');
    }
  }

  Future<PlansModel> getPlanById(String id) async {
    try {
      return await plansRemoteDatasource.getPlanById(id);
    } catch (e) {
      throw Exception('Failed to load plan: $e');
    }
  }
}
