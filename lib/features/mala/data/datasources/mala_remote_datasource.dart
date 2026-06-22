import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/mala/data/models/accumulator_model.dart';

class MalaRemoteDataSource {
  MalaRemoteDataSource({required this.dio});

  final Dio dio;
  final _logger = AppLogger('MalaRemoteDataSource');

  static const int _pageSize = 100;

  /// `GET /accumulators/presets` — preset accumulators (catalogue). Pages all.
  /// [language] localizes the embedded mantra title/text/pronunciation.
  Future<List<PresetAccumulatorModel>> fetchPresets({String? language}) async {
    try {
      final all = <PresetAccumulatorModel>[];
      var skip = 0;
      while (true) {
        final response = await dio.get(
          '/accumulators/presets',
          queryParameters: {
            'skip': skip,
            'limit': _pageSize,
            if (language != null) 'language': language,
          },
        );
        if (response.statusCode != 200) {
          throw _statusToException(
            response.statusCode,
            'Failed to load presets',
          );
        }
        final page = PresetAccumulatorsResponseModel.fromJson(
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
      _logger.error('Dio error in fetchPresets', e);
      throw _dioToException(e, 'Failed to load presets');
    }
  }

  /// `GET /accumulators/{parent_id}` — the user's detail for one preset.
  ///
  /// Returns `null` when the user has no accumulator for this preset yet
  /// (the endpoint 404s), so the caller can seed at 0 and lazily create.
  Future<AccumulatorDetailModel?> fetchAccumulatorDetail(
    String parentId,
  ) async {
    try {
      final response = await dio.get('/accumulators/$parentId');
      if (response.statusCode == 200) {
        return AccumulatorDetailModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      if (response.statusCode == 404) return null;
      throw _statusToException(response.statusCode, 'Failed to load detail');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _logger.error('Dio error in fetchAccumulatorDetail', e);
      throw _dioToException(e, 'Failed to load detail');
    }
  }

  /// `POST /accumulators/user` — create the user's accumulator for a preset.
  /// Body is just `{parent_id}`; the new accumulator starts at count 0.
  Future<AccumulatorModel> createUserAccumulator(String parentId) async {
    try {
      final response = await dio.post(
        '/accumulators/user',
        data: {'parent_id': parentId},
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
