import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-timer "dismissed today" markers (see
/// [StorageKeys.timerDismissedPrefix]).
///
/// A timer routine item can be dismissed for the current day from the timer
/// screen. While the marker equals today's date, the notification sync engine
/// skips today's occurrence (rolling the start / "timer up" reminders to
/// tomorrow) and the timer screen shows the next day's scheduled state. The
/// marker is compared by calendar date, so it resets on its own at midnight.
class TimerDismissStore {
  TimerDismissStore._();

  /// `yyyy-MM-dd` for [date]'s local calendar day — the value stored/compared.
  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _prefKey(String itemId) =>
      '${StorageKeys.timerDismissedPrefix}$itemId';

  /// Marks [itemId]'s timer as dismissed for today.
  static Future<void> markDismissedToday(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey(itemId), dateKey(DateTime.now()));
  }

  /// The dismissed-date marker for [itemId], or null if never dismissed.
  static Future<String?> dismissedDate(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey(itemId));
  }

  /// True when [itemId] is currently dismissed for today's calendar day.
  static Future<bool> isDismissedToday(String itemId) async {
    return await dismissedDate(itemId) == dateKey(DateTime.now());
  }

  /// Synchronous read from an already-loaded [prefs] instance — used by the
  /// notification sync engine, which holds a SharedPreferences handle.
  static bool isDismissedTodayFrom(SharedPreferences prefs, String itemId) {
    return prefs.getString(_prefKey(itemId)) == dateKey(DateTime.now());
  }
}
