import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/models/moon_phase.dart';
import 'package:intl/intl.dart';

/// A locale name safe to pass to `intl`'s [DateFormat] (and `table_calendar`).
///
/// `intl` ships no date-symbol data for some app locales (notably `bo`,
/// Tibetan), so `DateFormat.E('bo')` throws `Invalid locale "bo"`. We fall back
/// to `en` for date/number formatting when the active locale is unsupported —
/// mirroring what [MaterialLocalizationsBo] already does for Material widgets.
String dateFormatLocale(BuildContext context) {
  final locale = Localizations.localeOf(context).toString();
  final canonical = Intl.canonicalizedLocale(locale);
  return DateFormat.localeExists(canonical) ? canonical : 'en';
}

/// Localized display name for a [MoonPhase].
String moonPhaseLabel(AppLocalizations l10n, MoonPhase phase) {
  switch (phase) {
    case MoonPhase.newMoon:
      return l10n.moon_phase_new_moon;
    case MoonPhase.waxingCrescent:
      return l10n.moon_phase_waxing_crescent;
    case MoonPhase.firstQuarter:
      return l10n.moon_phase_first_quarter;
    case MoonPhase.waxingGibbous:
      return l10n.moon_phase_waxing_gibbous;
    case MoonPhase.fullMoon:
      return l10n.moon_phase_full_moon;
    case MoonPhase.waningGibbous:
      return l10n.moon_phase_waning_gibbous;
    case MoonPhase.lastQuarter:
      return l10n.moon_phase_last_quarter;
    case MoonPhase.waningCrescent:
      return l10n.moon_phase_waning_crescent;
  }
}

/// Display title for an event: a localized phase name for computed lunar-phase
/// events, otherwise the (backend-supplied) custom title.
String eventTitle(AppLocalizations l10n, CalendarEvent event) {
  final phase = event.phase;
  if (event.kind == CalendarEventKind.lunarPhase && phase != null) {
    return moonPhaseLabel(l10n, phase);
  }
  return event.title;
}

/// "{ordinal} lunar month" — e.g. "4th lunar month" in English. For non-English
/// locales the bare month number is interpolated (the arb template positions it
/// appropriately, e.g. "藏历4月").
String lunarMonthLabel(BuildContext context, AppLocalizations l10n, int month) {
  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
  final ordinal = isEnglish ? _englishOrdinal(month) : '$month';
  return l10n.calendar_lunar_month(ordinal);
}

String _englishOrdinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}
