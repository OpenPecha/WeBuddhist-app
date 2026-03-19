import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

/// Interceptor that logs all HTTP requests and responses.
///
/// Provides detailed logging for debugging API calls in development mode.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor(this._logger);

  final AppLogger _logger;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _logger.info('🌐 API Request: ${options.method} ${options.path}');
    _logger.debug('Headers: ${_filterHeaders(options.headers)}');
    if (options.data != null && options.data is! Map) {
      _logger.debug('Body: ${options.data}');
    } else if (options.queryParameters.isNotEmpty) {
      _logger.debug('Query: ${options.queryParameters}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final duration = response.requestOptions.extra['duration'] as Duration?;
    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    _logger.info(
      '✅ API Response: ${response.statusCode} '
      '${response.requestOptions.path}$durationStr',
    );
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    _logger.error(
      '❌ API Error: ${err.requestOptions.method} ${err.requestOptions.path} '
      '- ${err.response?.statusCode ?? err.type}',
      err.error,
      err.stackTrace,
    );
    handler.next(err);
  }

  /// Filter sensitive headers from logs
  Map<String, dynamic> _filterHeaders(Map<String, dynamic> headers) {
    final filtered = <String, dynamic>{};
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'authorization') {
        filtered[entry.key] = 'Bearer ***';
      } else {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered;
  }
}
