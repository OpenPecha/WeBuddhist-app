/// The eight moon phases of a 30-day Tibetan lunar month, mapped from the
/// lunar day number per the project's moon-phase chart.
enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

/// Maps a Tibetan lunar day (1–30) to its [MoonPhase].
///
/// Chart:
/// - 1 & 30 → new moon
/// - 2–7    → waxing crescent
/// - 8      → first quarter
/// - 9–14   → waxing gibbous
/// - 15     → full moon
/// - 16–21  → waning gibbous
/// - 22     → last quarter
/// - 23–29  → waning crescent
///
/// Day numbers are clamped into 1–30 so doubled/skipped days (which keep their
/// number) still resolve to a sensible phase.
MoonPhase moonPhaseForLunarDay(int lunarDay) {
  final day = lunarDay.clamp(1, 30);
  if (day == 1 || day == 30) return MoonPhase.newMoon;
  if (day <= 7) return MoonPhase.waxingCrescent;
  if (day == 8) return MoonPhase.firstQuarter;
  if (day <= 14) return MoonPhase.waxingGibbous;
  if (day == 15) return MoonPhase.fullMoon;
  if (day <= 21) return MoonPhase.waningGibbous;
  if (day == 22) return MoonPhase.lastQuarter;
  return MoonPhase.waningCrescent; // 23–29
}

extension MoonPhaseAssets on MoonPhase {
  /// File stem used for the phase's icon asset, e.g. `waxing_crescent`.
  String get assetName {
    switch (this) {
      case MoonPhase.newMoon:
        return 'new_moon';
      case MoonPhase.waxingCrescent:
        return 'waxing_crescent';
      case MoonPhase.firstQuarter:
        return 'first_quarter';
      case MoonPhase.waxingGibbous:
        return 'waxing_gibbous';
      case MoonPhase.fullMoon:
        return 'full_moon';
      case MoonPhase.waningGibbous:
        return 'waning_gibbous';
      case MoonPhase.lastQuarter:
        return 'last_quarter';
      case MoonPhase.waningCrescent:
        return 'waning_crescent';
    }
  }

  /// Asset path for this phase. The artwork is theme-neutral — the same file
  /// is used in light and dark mode (see [MoonPhaseIcon]).
  String assetPath() => 'assets/images/moon/$assetName.png';
}
