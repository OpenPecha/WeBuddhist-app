import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';

/// Query parameters for filtering and paginating plans
///
class PlansQueryParams {
  final String? search;
  final String? language;
  final String? tag;
  final int? skip;
  final int? limit;

  const PlansQueryParams({
    this.search,
    this.language,
    this.tag,
    this.skip = 0,
    this.limit = 20,
  });

  /// Convert to query parameters map
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (language != null) {
      params['language'] = language!;
    }

    if (search != null && search!.isNotEmpty) {
      params['search'] = search!;
    }

    if (tag != null && tag!.isNotEmpty) {
      params['tag'] = tag!;
    }

    if (skip != null) {
      params['skip'] = skip!;
    }

    if (limit != null) {
      params['limit'] = limit!;
    }

    return params;
  }
}

class PlansRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('PlansRemoteDatasource');

  PlansRemoteDatasource({required this.dio});

  // get all plans with filtering and pagination
  Future<List<PlansModel>> fetchPlans({
    required PlansQueryParams queryParams,
  }) async {
    try {
      final response = await dio.get(
        '/plans',
        queryParameters: queryParams.toQueryParams(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data['plans'] as List<dynamic>;
        return jsonData.map((json) => PlansModel.fromJson(json)).toList();
      } else {
        _logger.error('Failed to load plans: ${response.statusCode}');
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error in fetchPlans', e);
      throw Exception('Failed to load plans: $e');
    }
  }

  // get plan by id
  Future<PlansModel> getPlanById(String planId) async {
    try {
      final response = await dio.get('/plans/$planId');
      if (response.statusCode == 200) {
        return PlansModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load plan: $e');
    }
  }
}
