import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = AppLogger('PlanMetadataStore');

/// Enrollment metadata for a single plan.
class PlanMetadata {
  /// Day-1 anchor of the plan. Equals `plan.startDate ?? plan.startedAt`.
  /// For fixed-date plans this is the plan's scheduled start (e.g. May 13).
  /// For flexible plans this is when the user enrolled.
  ///
  /// All notification day-numbering is computed against this anchor.
  final DateTime effectiveStartDate;
  final int totalDays;

  const PlanMetadata({
    required this.effectiveStartDate,
    required this.totalDays,
  });

  @override
  String toString() =>
      'PlanMetadata(effectiveStartDate: ${effectiveStartDate.toIso8601String()}, totalDays: $totalDays)';
}

/// Synchronous-read store for enrolled plan metadata (effectiveStartDate + totalDays).
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

    final rawDate = prefs.getString(_anchorKey(planId));
    final totalDays = prefs.getInt(_totalDaysKey(planId));
    if (rawDate == null || totalDays == null) return null;

    final effectiveStartDate = DateTime.tryParse(rawDate);
    if (effectiveStartDate == null) {
      _logger.warning(
        '[NOTIF-META] failed to parse effectiveStartDate for $planId: "$rawDate"',
      );
      return null;
    }
    return PlanMetadata(
      effectiveStartDate: effectiveStartDate,
      totalDays: totalDays,
    );
  }

  /// Persists [effectiveStartDate] (plan day-1 anchor) and [totalDays] for [planId].
  static Future<void> setMetadata(
    String planId, {
    required DateTime effectiveStartDate,
    required int totalDays,
  }) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(
      _anchorKey(planId),
      effectiveStartDate.toIso8601String(),
    );
    await prefs.setInt(_totalDaysKey(planId), totalDays);
    _logger.info(
      '[NOTIF-META] stored $planId anchor=${effectiveStartDate.toIso8601String()} totalDays=$totalDays',
    );
  }

  /// Removes all metadata for [planId]. Call when the user removes the plan
  /// from their routine so a re-enrol starts fresh.
  static Future<void> clear(String planId) async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_anchorKey(planId));
    await prefs.remove(_totalDaysKey(planId));
  }

  /// Removes only the enrollment metadata (anchor + totalDays). Used when a
  /// plan leaves the routine or the enrollment list: metadata is re-mirrored
  /// from the server on re-add.
  static Future<void> clearEnrollmentMetadata(String planId) async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_anchorKey(planId));
    await prefs.remove(_totalDaysKey(planId));
  }

  /// Returns all plan IDs that have cached metadata.
  static List<String> getAllPlanIds() {
    return (_prefs?.getKeys() ?? const {})
        .where((k) => k.startsWith(StorageKeys.planStartedAtPrefix))
        .map((k) => k.replaceFirst(StorageKeys.planStartedAtPrefix, ''))
        .toList();
  }

  // ─── Cleanup ─────────────────────────────────────────────────────────────

  /// Removes all plan metadata. Call on logout so a new user starts with a
  /// clean slate.
  static Future<void> clearAll() async {
    final prefs = await _ensurePrefs();
    final toRemove = prefs.getKeys().where(
      (k) =>
          k.startsWith(StorageKeys.planStartedAtPrefix) ||
          k.startsWith(StorageKeys.planTotalDaysPrefix),
    );
    for (final key in toRemove.toList()) {
      await prefs.remove(key);
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  // Storage key is kept as `planStartedAtPrefix` for backwards compatibility
  // with previously stored values. Semantically it now holds the plan day-1
  // anchor (effectiveStartDate), not the user's enrollment timestamp.
  static String _anchorKey(String planId) =>
      '${StorageKeys.planStartedAtPrefix}$planId';

  static String _totalDaysKey(String planId) =>
      '${StorageKeys.planTotalDaysPrefix}$planId';

  static Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
}
