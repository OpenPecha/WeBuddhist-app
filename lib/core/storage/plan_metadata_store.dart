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

  /// Removes all metadata and shown flags for [planId]. Call when the user
  /// removes the plan from their routine so a re-enrol starts fresh.
  static Future<void> clear(String planId) async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_anchorKey(planId));
    await prefs.remove(_totalDaysKey(planId));
    await prefs.remove(_seriesScheduledKey(planId));
    for (final key in prefs.getKeys().where(_isShownFlagForPlan(planId)).toList()) {
      await prefs.remove(key);
    }
  }

  /// Removes only the enrollment metadata (anchor + totalDays), preserving
  /// the date-stamped delivery records (shown flags, series-scheduled
  /// marker). Used when a plan leaves the routine or the enrollment list:
  /// metadata is re-mirrored from the server on re-add, but the delivery
  /// records must survive the rest of the day so a same-day re-add cannot
  /// duplicate today's already-received notification. They expire naturally
  /// at midnight.
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

  /// Removes all per-date "immediate shown" flags for [planId] without
  /// touching the anchor/totalDays metadata. Call when the user removes the
  /// plan from a routine block so that re-adding treats it as fresh and
  /// re-fires today's immediate.
  static Future<void> clearShownFlags(String planId) async {
    final prefs = await _ensurePrefs();
    for (final key in prefs.getKeys().where(_isShownFlagForPlan(planId)).toList()) {
      await prefs.remove(key);
    }
  }

  // ─── Per-day "series handed to OS" marker ─────────────────────────────────
  //
  // Written when the engine schedules today's series notification ahead of
  // its fire time; cleared when that notification is cancelled before firing.
  // If the marker exists for today and the fire time has passed, the OS
  // delivered (or will deliver) the notification in the background — the
  // catch-up immediate must not fire again on next app open.
  // Used for both general and special plans (both are keyed by planId).

  /// True if today's series notification for [planId] was scheduled with the
  /// OS ahead of time on the calendar date of [date].
  static bool wasSeriesScheduledOn(String planId, DateTime date) {
    final raw = _prefs?.getString(_seriesScheduledKey(planId));
    if (raw == null) return false;
    final sep = raw.indexOf('|');
    final datePart = sep < 0 ? raw : raw.substring(0, sep);
    return datePart == _dateStamp(date);
  }

  /// Records that the series notification [notificationId] for [planId] was
  /// handed to the OS for delivery on [date].
  static Future<void> markSeriesScheduledOn(
    String planId,
    DateTime date,
    int notificationId,
  ) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(
      _seriesScheduledKey(planId),
      '${_dateStamp(date)}|$notificationId',
    );
  }

  /// Removes the series-scheduled marker for [planId]. Call when the pending
  /// notification it refers to is cancelled before firing, so the catch-up
  /// immediate can fire again if needed.
  static Future<void> clearSeriesScheduledMarker(String planId) async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_seriesScheduledKey(planId));
  }

  /// Reverse lookup for the engine's cancel pass: notification ID → planId
  /// for every marker stamped with [date]. Lets the engine clear the right
  /// marker when it cancels a pending same-day series notification.
  static Map<int, String> seriesScheduledIdsOn(DateTime date) {
    final prefs = _prefs;
    if (prefs == null) return const {};
    final stamp = _dateStamp(date);
    final result = <int, String>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(StorageKeys.planSeriesScheduledPrefix)) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      final sep = raw.indexOf('|');
      if (sep < 0 || raw.substring(0, sep) != stamp) continue;
      final id = int.tryParse(raw.substring(sep + 1));
      if (id == null) continue;
      result[id] = key.replaceFirst(StorageKeys.planSeriesScheduledPrefix, '');
    }
    return result;
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
          k.startsWith(StorageKeys.planImmediateShownPrefix) ||
          k.startsWith(StorageKeys.planSeriesScheduledPrefix),
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

  static String _immediateShownKey(String planId, DateTime date) =>
      '${StorageKeys.planImmediateShownPrefix}${planId}_${_dateStamp(date)}';

  static String _seriesScheduledKey(String planId) =>
      '${StorageKeys.planSeriesScheduledPrefix}$planId';

  static String _dateStamp(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static bool Function(String) _isShownFlagForPlan(String planId) =>
      (key) => key.startsWith('${StorageKeys.planImmediateShownPrefix}$planId');

  static Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
}
