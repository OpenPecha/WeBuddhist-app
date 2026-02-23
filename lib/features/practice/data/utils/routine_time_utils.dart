import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';

/// Minimum gap between time blocks in minutes.
const int kMinBlockGapMinutes = 10;

/// Maximum number of time blocks allowed (re-exported from RoutineData).
const int kMaxBlocks = RoutineData.maxBlocks;

// ============================================================================
// Time Formatting Utilities
// ============================================================================

/// Formats a [TimeOfDay] into a 12-hour format string (e.g., "12:30 PM").
///
/// This is the single source of truth for time formatting across the routine
/// feature to ensure consistency.
String formatRoutineTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

/// Converts a [TimeOfDay] to total minutes since midnight.
int timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

/// Converts total minutes since midnight to a [TimeOfDay].
TimeOfDay minutesToTime(int minutes) {
  final normalizedMinutes = minutes % 1440; // Wrap around midnight
  return TimeOfDay(
    hour: normalizedMinutes ~/ 60,
    minute: normalizedMinutes % 60,
  );
}

/// Total minutes in a day.
const int _minutesInDay = 1440;

/// Maximum search radius before giving up (half a day).
const int _maxSearchRadius = 720;

/// Given a picked time and existing block times (excluding the block being edited),
/// returns the nearest valid time that maintains a minimum gap from all other blocks.
/// If the picked time is already valid, returns it unchanged.
///
/// Returns null if no valid time slot is available (should only happen if
/// max blocks limit is exceeded with current gap requirements).
TimeOfDay? adjustTimeForMinimumGap(
  TimeOfDay picked,
  List<TimeOfDay> existingTimes,
) {
  if (existingTimes.isEmpty) return picked;

  // Early exit: Check if we've exceeded theoretical maximum
  // With 10-min gaps, max is 144 blocks (1440 / 10). With 20 block limit, always safe.
  if (existingTimes.length >= kMaxBlocks) {
    return null; // No room for more blocks
  }

  final pickedMin = picked.hour * 60 + picked.minute;
  final existingMin =
      existingTimes.map((t) => t.hour * 60 + t.minute).toList()..sort();

  if (_isValid(pickedMin, existingMin)) return picked;

  // Search outward from pickedMin in both directions
  // Limit search to half a day in each direction (720 minutes)
  for (int delta = 1; delta <= _maxSearchRadius; delta++) {
    final forward = (pickedMin + delta) % _minutesInDay;
    if (_isValid(forward, existingMin)) {
      return TimeOfDay(hour: forward ~/ 60, minute: forward % 60);
    }
    final backward = (pickedMin - delta + _minutesInDay) % _minutesInDay;
    if (_isValid(backward, existingMin)) {
      return TimeOfDay(hour: backward ~/ 60, minute: backward % 60);
    }
  }

  // No valid slot found within search radius
  return null;
}

/// Checks if adding a new block is allowed based on current count.
bool canAddBlock(int currentBlockCount) {
  return currentBlockCount < kMaxBlocks;
}

/// Returns the number of remaining blocks that can be added.
int remainingBlockSlots(int currentBlockCount) {
  return (kMaxBlocks - currentBlockCount).clamp(0, kMaxBlocks);
}

bool _isValid(int candidate, List<int> existingMinutes) {
  for (final m in existingMinutes) {
    int diff = (candidate - m).abs();
    if (diff > _maxSearchRadius) diff = _minutesInDay - diff; // wrap around midnight
    if (diff < kMinBlockGapMinutes) return false;
  }
  return true;
}
