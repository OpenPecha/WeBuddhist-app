import 'package:flutter_timezone/flutter_timezone.dart';

/// Resolves the device timezone as an IANA identifier for API headers.
///
/// Used by [TimezoneInterceptor] so endpoints like `/verse-of-day/today` can
/// determine the user's local calendar date.
///
/// Each [resolve] reads the OS timezone (concurrent callers share one read).
/// There is no session-long cache, so travel, DST, and manual timezone changes
/// are picked up on the next API call without lifecycle hooks.
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

  /// Dedupes concurrent [resolve] calls into a single platform read.
  static Future<String>? _inFlight;

  /// Returns the device IANA timezone (e.g. `America/New_York`), falling back
  /// to `UTC` when the OS reports an unknown identifier.
  static Future<String> resolve() {
    return _inFlight ??= _readFromDevice().whenComplete(() => _inFlight = null);
  }

  static Future<String> _readFromDevice() async {
    final device = await FlutterTimezone.getLocalTimezone();
    final trimmed = device.trim();
    if (trimmed.isEmpty) return 'UTC';
    return _legacyToIana[trimmed] ?? trimmed;
  }
}
