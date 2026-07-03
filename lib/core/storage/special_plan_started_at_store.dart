import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = AppLogger('SpecialPlanStartedAtStore');

/// Synchronous-read store for special-plan `startedAt` dates.
///
/// The notification scheduler is a non-Riverpod singleton invoked from
/// background contexts, so it cannot await SharedPreferences each time.
/// We cache the instance once at startup via [init] and expose synchronous
/// getters. Source of truth is always the server's [UserPlansModel.startedAt].
class SpecialPlanStartedAtStore {
  SpecialPlanStartedAtStore._();

  static SharedPreferences? _prefs;

  /// Initialises the cached [SharedPreferences] instance. Safe to call
  /// multiple times — no-op after the first successful call.
  static Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── startedAt ───────────────────────────────────────────────────────────

  /// Returns the cached `startedAt` for [planId], or `null` if unknown.
  static DateTime? getStartedAt(String planId) {
    final raw = _prefs?.getString(_startedAtKey(planId));
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      _logger.warning('Failed to parse startedAt for $planId: "$raw"');
    }
    return parsed;
  }

  /// Persists [startedAt] for [planId].
  static Future<void> setStartedAt(String planId, DateTime startedAt) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_startedAtKey(planId), startedAt.toIso8601String());
  }

  /// Removes only the cached startedAt. startedAt is re-mirrored from server
  /// truth on the next plans refresh.
  static Future<void> clearStartedAtOnly(String planId) async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_startedAtKey(planId));
  }

  /// Removes the startedAt entry for [planId]. Call when the user removes
  /// the plan from their routine so a subsequent re-enrol is treated as fresh.
  static Future<void> clear(String planId) async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_startedAtKey(planId));
  }

  /// Removes all special-plan entries. Call on logout so a different user
  /// signing in starts with a clean slate.
  static Future<void> clearAll() async {
    final prefs = await _ensurePrefs();
    final toRemove = prefs.getKeys().where(
      (k) => k.startsWith(StorageKeys.specialPlanStartedAtPrefix),
    );
    for (final key in toRemove.toList()) {
      await prefs.remove(key);
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  static String _startedAtKey(String planId) =>
      '${StorageKeys.specialPlanStartedAtPrefix}$planId';

  static Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
}
