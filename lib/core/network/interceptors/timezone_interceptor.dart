import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/iana_timezone.dart';

/// Adds the device IANA timezone to every outgoing request.
///
/// The Pecha API uses [IanaTimezone.headerName] to resolve "today" in the
/// user's local calendar (e.g. `/verse-of-day/today`).
class TimezoneInterceptor extends Interceptor {
  TimezoneInterceptor(this._logger);

  final AppLogger _logger;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.headers.containsKey(IanaTimezone.headerName)) {
      try {
        options.headers[IanaTimezone.headerName] = await IanaTimezone.resolve();
      } catch (e, st) {
        _logger.warning('Failed to resolve device timezone, using UTC', e, st);
        options.headers[IanaTimezone.headerName] = 'UTC';
      }
    }

    handler.next(options);
  }
}
