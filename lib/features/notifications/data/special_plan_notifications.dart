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

import 'package:flutter_pecha/core/utils/app_logger.dart';

final _logger = AppLogger('SpecialPlanNotifications');

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
const String kItccPlan7to37Id = '509657b5-7af5-45de-b22d-0ea2fe094424';

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
      title: 'ITCC: Days 1-6',
      body:
          "Welcome to day 2. Yesterday we mapped the universe of phenomena using groups of three. Today look at phenomena as dualities like conditioned and unconditioned.",
      buttonText: 'START',
    ),
    DayNotification(
      title: "Today's tip",
      body:
          'Did you know, you can tap "Edit" on the Practice page to update when you receive reminders?',
    ),
    DayNotification(
      title: "Today's Pali word: kilesa",
      body:
          '"Kilesa" means defilements, or mental forces that corrupt and stain the mind. The Abhidhamma identifies ten root defilements. Learn more in the app.',
      buttonText: 'START NOW',
    ),
    DayNotification(
      title: 'A verse for today',
      body:
          'Today\'s verses include lines like "States that lead to liberation. States that do not lead to liberation." setting up deep discussions in upcoming sessions.',
      buttonText: 'READ ON',
    ),
    DayNotification(
      title: 'Last session of part 1',
      body:
          "Today marks a significant step: finishing part 1 - and tomorrow, you'll begin part 2.",
      buttonText: 'GOTO APP',
    ),
  ],
  kItccPlan7to37Id: <DayNotification>[
    DayNotification(
      title: 'Welcome to ITCC: Days 7-37',
      body:
          'Today we begin Cittuppādakaṇḍaṃ, the Chapter on the Arising of Consciousness and look at the mind when something wholesome arises.',
      buttonText: 'Read Now',
    ),
    DayNotification(
      title: 'A verse for today',
      body:
          '"Whatever at that time is mindfulness, recollection, the holding, the not floating away, the not forgetting — this at that time is the power of mindfulness."',
      buttonText: 'Start Session',
    ),
    DayNotification(
      title: "Today's Pali word: Khandha",
      body:
          '"Khanda" means heap or aggregate. Today\'s verses analyze a mind-moment via four immaterial aggregates — feeling, perception, formations, and consciousness — and the material one, form.',
      buttonText: 'Open App',
    ),
    DayNotification(
      title: 'The path in every moment',
      body:
          'Right view, thought, effort, mindfulness, concentration — the five path-factors are present in every wholesome mind.',
      buttonText: 'Begin',
    ),
    DayNotification(
      title: "Question for today's session",
      body:
          'Of these five types of wholesome mind — with joy or equanimity, with knowledge or without, spontaneous or prompted — which feels closest to this moment?',
      buttonText: 'Start Reading',
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
  _logger.info(
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
    _logger.info('[SP-RESOLVER] planId=$planId is NOT a special plan');
    return null;
  }
  final index = _daysSince(startedAt, now);
  if (index < 0 || index >= entries.length) {
    _logger.info(
      '[SP-RESOLVER] index=$index out of range '
      '[0..${entries.length - 1}] for planId=$planId -> null',
    );
    return null;
  }
  final entry = entries[index];
  _logger.info(
    '[SP-RESOLVER] planId=$planId day=${index + 1} '
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
