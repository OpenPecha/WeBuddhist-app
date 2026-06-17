import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/mala/data/models/accumulator_model.dart';
import 'package:flutter_pecha/features/mala/data/models/mantra_model.dart';

class MalaRemoteDataSource {
  MalaRemoteDataSource({required this.dio});

  final Dio dio;
  final _logger = AppLogger('MalaRemoteDataSource');

  static const int _pageSize = 100;

  /// `GET /accumulators` — preset accumulators (templates). Pages through all.
  Future<List<AccumulatorModel>> fetchPresetAccumulators() =>
      _fetchAllPages('/accumulators');

  /// `GET /accumulators/user` — the current user's own accumulators.
  Future<List<AccumulatorModel>> fetchUserAccumulators() =>
      _fetchAllPages('/accumulators/user');

  /// `GET /mantra` — localized mantra content.
  Future<List<MantraContentModel>> fetchMantras({String? language}) async {
    try {
      final response = await dio.get(
        '/mantra',
        queryParameters: {if (language != null) 'language': language},
      );
      if (response.statusCode == 200) {
        return MantraResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        ).mantras;
      }
      throw _statusToException(response.statusCode, 'Failed to load mantras');
    } on DioException catch (e) {
      _logger.error('Dio error in fetchMantras', e);
      throw _dioToException(e, 'Failed to load mantras');
    }
  }

  /// `POST /accumulators/user` — create the user's accumulator for a preset.
  Future<AccumulatorModel> createUserAccumulator({
    required String name,
    String? mantraId,
    String? textId,
    required int currentCount,
  }) async {
    try {
      final response = await dio.post(
        '/accumulators/user',
        data: {
          'name': name,
          'current_count': currentCount,
          if (mantraId != null) 'mantra_id': mantraId,
          if (textId != null) 'text_id': textId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AccumulatorModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw _statusToException(
        response.statusCode,
        'Failed to create accumulator',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in createUserAccumulator', e);
      throw _dioToException(e, 'Failed to create accumulator');
    }
  }

  /// `PUT /accumulators/user/{id}` — push the absolute lifetime total.
  Future<AccumulatorModel> updateUserAccumulator({
    required String accumulatorId,
    required int currentCount,
  }) async {
    try {
      final response = await dio.put(
        '/accumulators/user/$accumulatorId',
        data: {'current_count': currentCount},
      );
      if (response.statusCode == 200) {
        return AccumulatorModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw _statusToException(
        response.statusCode,
        'Failed to update accumulator',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in updateUserAccumulator', e);
      throw _dioToException(e, 'Failed to update accumulator');
    }
  }

  Future<List<AccumulatorModel>> _fetchAllPages(String path) async {
    try {
      final all = <AccumulatorModel>[];
      var skip = 0;
      while (true) {
        final response = await dio.get(
          path,
          queryParameters: {'skip': skip, 'limit': _pageSize},
        );
        if (response.statusCode != 200) {
          throw _statusToException(response.statusCode, 'Failed to load $path');
        }
        final page = AccumulatorsResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        all.addAll(page.accumulators);
        skip += _pageSize;
        if (page.accumulators.length < _pageSize || all.length >= page.total) {
          break;
        }
      }
      return all;
    } on DioException catch (e) {
      _logger.error('Dio error loading $path', e);
      throw _dioToException(e, 'Failed to load $path');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Not found');
    } else if (statusCode == 429) {
      return const RateLimitException('Too many requests');
    } else {
      return ServerException('$label: $statusCode');
    }
  }

  Exception _dioToException(DioException e, String label) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Connection timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      return const NetworkException('No internet connection');
    } else if (e.response?.statusCode != null) {
      return _statusToException(e.response!.statusCode, label);
    } else {
      return const NetworkException('Network error');
    }
  }
}
