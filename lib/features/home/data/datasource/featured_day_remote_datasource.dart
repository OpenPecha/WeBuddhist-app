import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/plans/data/models/response/featured_day_response.dart';

class FeaturedDayRemoteDatasource {
  final Dio dio;

  FeaturedDayRemoteDatasource({required this.dio});

  Future<FeaturedDayResponse> fetchFeaturedDay({String? language}) async {
    try {
      final response = await dio.get(
        '/plans/featured/day',
        queryParameters: language != null ? {'language': language} : null,
      );

      if (response.statusCode == 200) {
        return FeaturedDayResponse.fromJson(response.data);
      } else {
        return FeaturedDayResponse.fromJson({
          'id': '',
          'day_number': 0,
          'tasks': [],
        });
      }
    } catch (e) {
      throw Exception('Faild in fetching featured day: $e');
    }
  }
}
