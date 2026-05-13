import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = AppLogger('PlanMetadataStore');

/// Enrollment metadata for a single plan.
class PlanMetadata {
  final DateTime startedAt;
  final int totalDays;

  const PlanMetadata({required this.startedAt, required this.totalDays});

  @override
  String toString() =>
      'PlanMetadata(startedAt: ${startedAt.toIso8601String()}, totalDays: $totalDays)';
}

/// Synchronous-read store for enrolled plan metadata (startedAt + totalDays).
///
/// The notification scheduler is a non-Riverpod singleton invoked from
/// background contexts, so it cannot await SharedPreferences each time.
/// We cache the instance once at startup via [init] and expose synchronous
/// getters. Source of truth is always the server's [UserPlansModel].
class PlanMetadataStore {
  PlanMetadataStore._();

  static SharedPreferences? _prefs;

  /// Initialises the cached SharedPreferences instance. Safe to call
  /// multiple times — no-op after the first successful call.
  static Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Metadata ────────────────────────────────────────────────────────────

  /// Returns cached metadata for [planId], or `null` if unknown.
  static PlanMetadata? getMetadata(String planId) {
    final prefs = _prefs;
    if (prefs == null) return null;

    final rawDate = prefs.getString(_startedAtKey(planId));
    final totalDays = prefs.getInt(_totalDaysKey(planId));
    if (rawDate == null || totalDays == null) return null;

    final startedAt = DateTime.tryParse(rawDate);
    if (startedAt == null) {
      _logger.warning('Failed to parse startedAt for $planId: "$rawDate"');
      return null;
    }
    return PlanMetadata(startedAt: startedAt, totalDays: totalDays);
  }

  /// Persists [startedAt] and [totalDays] for [planId].
  static Future<void> setMetadata(
    String planId, {
    required DateTime startedAt,
    required int totalDays,
  }) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_startedAtKey(planId), startedAt.toIso8601String());
    await prefs.setInt(_totalDaysKey(planId), totalDays);
  }

  /// Removes all metadata and shown flags for [planId]. Call when the user
  /// removes the plan from their routine so a re-enrol starts fresh.
  static Future<void> clear(String planId) async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_startedAtKey(planId));
    await prefs.remove(_totalDaysKey(planId));
    for (final key in prefs.getKeys().where(_isShownFlagForPlan(planId)).toList()) {
      await prefs.remove(key);
    }
  }

  /// Returns all plan IDs that have cached metadata.
  static List<String> getAllPlanIds() {
    return (_prefs?.getKeys() ?? const {})
        .where((k) => k.startsWith(StorageKeys.planStartedAtPrefix))
        .map((k) => k.replaceFirst(StorageKeys.planStartedAtPrefix, ''))
        .toList();
  }

  // ─── Per-date immediate-fire idempotency ──────────────────────────────────

  /// True if an immediate notification has already been shown for [planId]
  /// on the calendar date of [date].
  static bool wasImmediateShownOn(String planId, DateTime date) {
    return _prefs?.getBool(_immediateShownKey(planId, date)) ?? false;
  }

  /// Records that an immediate notification was shown for [planId] on [date].
  static Future<void> markImmediateShownOn(String planId, DateTime date) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_immediateShownKey(planId, date), true);
  }

  // ─── Cleanup ─────────────────────────────────────────────────────────────

  /// Removes all plan metadata and shown flags. Call on logout so a new
  /// user starts with a clean slate.
  static Future<void> clearAll() async {
    final prefs = await _ensurePrefs();
    final toRemove = prefs.getKeys().where(
      (k) =>
          k.startsWith(StorageKeys.planStartedAtPrefix) ||
          k.startsWith(StorageKeys.planTotalDaysPrefix) ||
          k.startsWith(StorageKeys.planImmediateShownPrefix),
    );
    for (final key in toRemove.toList()) {
      await prefs.remove(key);
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  static String _startedAtKey(String planId) =>
      '${StorageKeys.planStartedAtPrefix}$planId';

  static String _totalDaysKey(String planId) =>
      '${StorageKeys.planTotalDaysPrefix}$planId';

  static String _immediateShownKey(String planId, DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${StorageKeys.planImmediateShownPrefix}${planId}_$y-$m-$d';
  }

  static bool Function(String) _isShownFlagForPlan(String planId) =>
      (key) => key.startsWith('${StorageKeys.planImmediateShownPrefix}$planId');

  static Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
}
