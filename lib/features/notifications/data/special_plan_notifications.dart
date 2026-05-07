/// Hard-coded per-day notification content for "special" plans whose daily
/// routine notification should display different copy on each of the first N
/// days after enrollment, after which the series ends and no further
/// notifications fire for that plan.
///
/// Day index = `floor(today_local - startedAt_local) + 1`, where startedAt is
/// the server-truth `UserPlansModel.startedAt`. Day 1 corresponds to index 0.
///
/// Add a new plan: insert another entry into [kSpecialPlanNotifications].
/// Change copy: edit the relevant [DayNotification].
/// No other code changes required.
library;

class DayNotification {
  final String title;
  final String body;

  /// Optional Android action-button label (e.g. "START", "READ ON").
  /// `null` → no action button. iOS never renders this label per product
  /// decision (avoids upfront iOS category registration). Body tap on iOS
  /// routes to the same destination, so functionality is preserved.
  final String? buttonText;

  const DayNotification({
    required this.title,
    required this.body,
    this.buttonText,
  });
}

/// ITCC "Abhidhamma in a Year" plan ID.
/// Mirrors `kOnboardingEvents` in onboarding_preferences.dart.
const String kItccPlanId = 'b42c9270-8bc9-4a98-b375-924a948ab18e';

/// Daily fire time for the special-plan series (local time). Mirrors the
/// 09:00 routine block the event-enrollment flow creates server-side.
const int kSpecialPlanFireHour = 9;
const int kSpecialPlanFireMinute = 0;

const Map<String, List<DayNotification>> kSpecialPlanNotifications = {
  kItccPlanId: <DayNotification>[
    DayNotification(
      title: 'Welcome to the course',
      body:
          "Your journey to Bodhgaya begins today. If you haven't already started, jump right in.",
    ),
    DayNotification(
      title: 'Abhidhamma in a Year',
      body:
          "Welcome to day 2 of Abhidhamma in a Year. Today's reading is short — start here.",
      buttonText: 'START',
    ),
    DayNotification(
      title: "Today's tip",
      body:
          'Did you know, you can tap "Edit" on the Practice page to update your reminders?',
    ),
    DayNotification(
      title: "Today's Pali word: kusula",
      body: 'wholesome, as in kusula dhamma, wholesome phenomena.',
      buttonText: 'START NOW',
    ),
    DayNotification(
      title: 'A verse for today',
      body:
          '"They have gone to the state of arising together etc. with joy..." Continue in app.',
      buttonText: 'READ ON',
    ),
    DayNotification(
      title: 'Today: Intro to the Matrix',
      body:
          "In today's reading, you'll learn the most important Abhidhamma terms.",
      buttonText: 'GOTO APP',
    ),
    DayNotification(
      title: '196 days until Bodhgaya 🪷',
      body:
          'Every day of preparation brings the chanting closer. Open today\'s session.',
    ),
    DayNotification(
      title: "You're almost there",
      body:
          "One more session to go in Part One. The path continues — open today's reading.",
    ),
  ],
};

/// True if [planId] has a special-plan series configured.
bool isSpecialPlan(String planId) =>
    kSpecialPlanNotifications.containsKey(planId);

int _daysSince(DateTime startedAt, DateTime now) {
  final startLocal = startedAt.toLocal();
  final nowLocal = now.toLocal();
  final start = DateTime(startLocal.year, startLocal.month, startLocal.day);
  final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  final days = today.difference(start).inDays;
  // ignore: avoid_print
  print(
    '[SP-RESOLVER] _daysSince startedAt=$startedAt (local=$startLocal) '
    'now=$now (local=$nowLocal) -> days=$days',
  );
  return days;
}

/// Returns the day-N notification content for [planId] given [startedAt],
/// or `null` if [planId] is not a special plan, [startedAt] is in the future,
/// or the series has ended.
DayNotification? resolveSpecialPlanNotification({
  required String planId,
  required DateTime startedAt,
  required DateTime now,
}) {
  final entries = kSpecialPlanNotifications[planId];
  if (entries == null) {
    // ignore: avoid_print
    print('[SP-RESOLVER] resolveSpecialPlanNotification: planId=$planId is NOT a special plan');
    return null;
  }
  final index = _daysSince(startedAt, now);
  if (index < 0 || index >= entries.length) {
    // ignore: avoid_print
    print(
      '[SP-RESOLVER] resolveSpecialPlanNotification: index=$index out of range '
      '[0..${entries.length - 1}] for planId=$planId -> null',
    );
    return null;
  }
  final entry = entries[index];
  // ignore: avoid_print
  print(
    '[SP-RESOLVER] resolveSpecialPlanNotification: planId=$planId day=${index + 1} '
    'title="${entry.title}" button="${entry.buttonText}"',
  );
  return entry;
}

/// True if the special-plan series for [planId] has ended (used to suppress
/// the daily routine notification after the last day).
bool isSpecialPlanSeriesEnded({
  required String planId,
  required DateTime startedAt,
  required DateTime now,
}) {
  final entries = kSpecialPlanNotifications[planId];
  if (entries == null) return false;
  return _daysSince(startedAt, now) >= entries.length;
}

/// 1-based day index for [planId] given [startedAt]. Returns null if not a
/// special plan, before-start, or past series length.
int? specialPlanDayIndex({
  required String planId,
  required DateTime startedAt,
  required DateTime now,
}) {
  final entries = kSpecialPlanNotifications[planId];
  if (entries == null) return null;
  final daysSince = _daysSince(startedAt, now);
  if (daysSince < 0 || daysSince >= entries.length) return null;
  return daysSince + 1;
}
