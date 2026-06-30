import 'package:flutter_timezone/flutter_timezone.dart';

/// Resolves the device timezone as an IANA identifier for API headers.
///
/// Used by [TimezoneInterceptor] so endpoints like `/verse-of-day/today` can
/// determine the user's local calendar date.
class IanaTimezone {
  IanaTimezone._();

  /// Header name expected by the Pecha API (e.g. verse-of-day).
  static const headerName = 'X-Timezone';

  /// Legacy OS identifiers mapped to canonical IANA names.
  static const _legacyToIana = {
    'Asia/Calcutta': 'Asia/Kolkata',
    'US/Eastern': 'America/New_York',
    'US/Central': 'America/Chicago',
    'US/Mountain': 'America/Denver',
    'US/Pacific': 'America/Los_Angeles',
    'GMT': 'UTC',
  };

  static String? _cached;

  /// Returns the device IANA timezone (e.g. `America/New_York`), falling back
  /// to `UTC` when the OS reports an unknown identifier.
  static Future<String> resolve() async {
    if (_cached != null) return _cached!;

    final device = await FlutterTimezone.getLocalTimezone();
    final trimmed = device.trim();
    if (trimmed.isEmpty) {
      _cached = 'UTC';
      return _cached!;
    }

    _cached = _legacyToIana[trimmed] ?? trimmed;
    return _cached!;
  }

  /// Clears the in-memory cache (e.g. after an OS timezone change).
  static void invalidateCache() => _cached = null;
}
