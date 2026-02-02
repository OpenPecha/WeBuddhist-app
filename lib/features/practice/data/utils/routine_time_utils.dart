import 'package:flutter/material.dart';

const int kMinBlockGapMinutes = 10;

/// Given a picked time and existing block times (excluding the block being edited),
/// returns the nearest valid time that maintains a minimum gap from all other blocks.
/// If the picked time is already valid, returns it unchanged.
TimeOfDay adjustTimeForMinimumGap(
  TimeOfDay picked,
  List<TimeOfDay> existingTimes,
) {
  if (existingTimes.isEmpty) return picked;

  final pickedMin = picked.hour * 60 + picked.minute;
  final existingMin =
      existingTimes.map((t) => t.hour * 60 + t.minute).toList()..sort();

  if (_isValid(pickedMin, existingMin)) return picked;

  // Search outward from pickedMin in both directions
  for (int delta = 1; delta < 1440; delta++) {
    final forward = (pickedMin + delta) % 1440;
    if (_isValid(forward, existingMin)) {
      return TimeOfDay(hour: forward ~/ 60, minute: forward % 60);
    }
    final backward = (pickedMin - delta + 1440) % 1440;
    if (_isValid(backward, existingMin)) {
      return TimeOfDay(hour: backward ~/ 60, minute: backward % 60);
    }
  }

  return picked; // fallback — should never happen with < 144 blocks
}

bool _isValid(int candidate, List<int> existingMinutes) {
  for (final m in existingMinutes) {
    int diff = (candidate - m).abs();
    if (diff > 720) diff = 1440 - diff; // wrap around midnight
    if (diff < kMinBlockGapMinutes) return false;
  }
  return true;
}
