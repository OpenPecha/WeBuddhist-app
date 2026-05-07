import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Synchronous-read store for special-plan `startedAt` dates.
///
/// The notification scheduler (`RoutineNotificationService`) is a non-Riverpod
/// singleton invoked from background contexts, so it cannot await a
/// SharedPreferences load each time it schedules. Instead, we cache the
/// `SharedPreferences` instance once at startup via [init] and expose
/// synchronous getters.
///
/// Source of truth for `startedAt` is the server's `UserPlansModel.startedAt`.
/// We mirror it here so the day-N resolver works without going through the
/// plans repository at schedule time.
class SpecialPlanStartedAtStore {
  SpecialPlanStartedAtStore._();

  static SharedPreferences? _prefs;

  /// Initialize the cached [SharedPreferences] instance. Safe to call multiple
  /// times — second call is a no-op once primed. Call early in app startup
  /// (before any notification scheduling).
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String _key(String planId) =>
      '${StorageKeys.specialPlanStartedAtPrefix}$planId';

  /// Reads the `startedAt` for [planId], or `null` if unknown.
  /// Returns `null` when [init] has not run yet.
  static DateTime? getStartedAt(String planId) {
    final prefs = _prefs;
    if (prefs == null) return null;
    final raw = prefs.getString(_key(planId));
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Persists [startedAt] for [planId]. Async because SharedPreferences write
  /// goes to disk; the in-memory cache is updated synchronously by the plugin.
  static Future<void> setStartedAt(String planId, DateTime startedAt) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_key(planId), startedAt.toIso8601String());
    // ignore: avoid_print
    print(
      '[SP-STORE] setStartedAt planId=$planId startedAt=${startedAt.toIso8601String()}',
    );
  }

  /// Removes the entry for [planId].
  static Future<void> clear(String planId) async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_key(planId));
  }

  /// Removes all special-plan startedAt entries AND day-1-shown flags.
  /// Use on logout so a different user signing in starts fresh.
  static Future<void> clearAll() async {
    final prefs = await _ensurePrefs();
    final keysToRemove = prefs
        .getKeys()
        .where(
          (k) =>
              k.startsWith(StorageKeys.specialPlanStartedAtPrefix) ||
              k.startsWith(StorageKeys.specialPlanDay1ShownPrefix),
        )
        .toList();
    for (final k in keysToRemove) {
      await prefs.remove(k);
    }
  }

  /// True if the Day 1 immediate-fire notification has already been shown for
  /// [planId] given the [startedAt] date (date-only key).
  static bool wasDay1Shown(String planId, DateTime startedAt) {
    final prefs = _prefs;
    if (prefs == null) return false;
    return prefs.getBool(_day1Key(planId, startedAt)) ?? false;
  }

  /// Marks Day 1 as shown for [planId] on [startedAt]'s date.
  static Future<void> markDay1Shown(String planId, DateTime startedAt) async {
    final prefs = await _ensurePrefs();
    final key = _day1Key(planId, startedAt);
    await prefs.setBool(key, true);
    // ignore: avoid_print
    print('[SP-STORE] markDay1Shown key=$key value=true');
  }

  static String _day1Key(String planId, DateTime startedAt) {
    final y = startedAt.year.toString().padLeft(4, '0');
    final m = startedAt.month.toString().padLeft(2, '0');
    final d = startedAt.day.toString().padLeft(2, '0');
    return '${StorageKeys.specialPlanDay1ShownPrefix}${planId}_$y-$m-$d';
  }

  static Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
}
