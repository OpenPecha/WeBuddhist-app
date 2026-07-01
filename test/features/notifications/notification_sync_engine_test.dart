import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/notifications/data/notification_id_scheme.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Pure-compute tests for `NotificationSyncEngine.computeForPlanBlock` and
/// `computeForRecitationBlock` (the `@visibleForTesting` helpers). These
/// avoid the platform plugin and SharedPreferences — only the timezone
/// package needs initialising.
void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  // The engine instance is only used to invoke the pure compute helpers;
  // its plugin/service dependencies are never touched on this path.
  late NotificationSyncEngine engine;

  setUp(() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    engine = container.read(notificationSyncEngineProvider);
  });

  // ─── Helpers ───────────────────────────────────────────────────────────────

  RoutineItem planItem(String id, {String title = 'Plan A'}) => RoutineItem(
        id: id,
        title: title,
        type: RoutineItemType.series,
      );

  RoutineItem recitationItem({String id = 'r-1'}) => RoutineItem(
        id: id,
        title: 'Recitation',
        type: RoutineItemType.recitation,
      );

  RoutineBlock planBlock({
    String id = 'b-1',
    int hour = 7,
    int minute = 0,
    List<RoutineItem>? items,
    bool notificationEnabled = true,
  }) =>
      RoutineBlock(
        id: id,
        time: TimeOfDay(hour: hour, minute: minute),
        notificationEnabled: notificationEnabled,
        items: items ?? [planItem('plan-1')],
        notificationId: 1001,
      );

  UserPlansModel makePlan({
    String id = 'plan-1',
    DateTime? startedAt,
    DateTime? startDate,
    int totalDays = 30,
  }) =>
      UserPlansModel(
        id: id,
        title: 'A Plan',
        description: '',
        language: 'en',
        difficultyLevel: null,
        startedAt: startedAt ?? DateTime(2026, 6, 1),
        totalDays: totalDays,
        tags: null,
        startDate: startDate,
      );

  // ─── Plan-block compute ────────────────────────────────────────────────────

  group('case 5a/5b: toggle gates', () {
    test('returns empty when master OFF', () {
      final entries = engine.computeForPlanBlock(
        planBlock(),
        planItem('plan-1'),
        makePlan(),
        DateTime(2026, 6, 5, 8),
        masterOn: false,
        routineOn: true,
      );
      expect(entries, isEmpty);
    });

    test('returns empty when routine sub-toggle OFF', () {
      final entries = engine.computeForPlanBlock(
        planBlock(),
        planItem('plan-1'),
        makePlan(),
        DateTime(2026, 6, 5, 8),
        masterOn: true,
        routineOn: false,
      );
      expect(entries, isEmpty);
    });
  });

  group('case 3c: plan already ended', () {
    test('emits nothing when today > planEnd', () {
      final entries = engine.computeForPlanBlock(
        planBlock(),
        planItem('plan-1'),
        makePlan(
          startedAt: DateTime(2026, 1, 1),
          totalDays: 10, // ends 2026-01-10
        ),
        DateTime(2026, 6, 5, 8),
        masterOn: true,
        routineOn: true,
      );
      expect(entries, isEmpty);
    });
  });

  group('case 3a: plan starts in the future', () {
    test('schedules only future days, no immediate catch-up', () {
      final entries = engine.computeForPlanBlock(
        planBlock(hour: 9),
        planItem('plan-1'),
        makePlan(
          startedAt: DateTime(2026, 7, 1),
          totalDays: 5,
        ),
        DateTime(2026, 6, 25, 10),
        masterOn: true,
        routineOn: true,
      );
      expect(entries, isNotEmpty);
      expect(entries.every((e) => e.fireAt != null), isTrue);
      expect(entries.every((e) => !e.isImmediate), isTrue);
    });
  });

  group('case 3b: plan in progress', () {
    test('emits an immediate when today block-time has already passed', () {
      final entries = engine.computeForPlanBlock(
        planBlock(hour: 7, minute: 0),
        planItem('plan-1'),
        makePlan(
          startedAt: DateTime(2026, 6, 1),
          totalDays: 30,
        ),
        // 09:00 — past the 07:00 block time
        DateTime(2026, 6, 5, 9),
        masterOn: true,
        routineOn: true,
      );
      final immediates = entries.where((e) => e.isImmediate).toList();
      expect(immediates, hasLength(1));
      expect(immediates.first.debugCase, contains('3b'));
    });

    test('no immediate when today block-time has not yet passed', () {
      final entries = engine.computeForPlanBlock(
        planBlock(hour: 9, minute: 0),
        planItem('plan-1'),
        makePlan(
          startedAt: DateTime(2026, 6, 1),
          totalDays: 30,
        ),
        DateTime(2026, 6, 5, 8),
        masterOn: true,
        routineOn: true,
      );
      expect(entries.any((e) => e.isImmediate), isFalse);
    });

    test(
        'explicit re-add with a later time today re-arms today\'s entry '
        '(deliberately scheduled fires are always honored) but never emits '
        'a catch-up', () {
      final entries = engine.computeForPlanBlock(
        // Block re-created at 16:00 after today's notification already
        // fired at an earlier time (marker present).
        planBlock(hour: 16, minute: 0),
        planItem('plan-1'),
        makePlan(
          startedAt: DateTime(2026, 6, 1),
          totalDays: 30,
        ),
        DateTime(2026, 6, 5, 15, 36),
        masterOn: true,
        routineOn: true,
        seriesScheduledTodayByOS: true,
      );
      // No instant duplicate of already-received content…
      expect(entries.any((e) => e.isImmediate), isFalse);
      // …but the user's explicit 16:00 choice fires today at 16:00.
      expect(
        entries.any((e) =>
            e.fireAt != null &&
            e.fireAt!.month == 6 &&
            e.fireAt!.day == 5 &&
            e.fireAt!.hour == 16),
        isTrue,
      );
      // Tomorrow onwards scheduled as usual.
      expect(
        entries.any((e) =>
            e.fireAt != null &&
            e.fireAt!.month == 6 &&
            e.fireAt!.day == 6),
        isTrue,
      );
    });

    test(
        'no immediate when the OS already owned today\'s delivery '
        '(background-fired notification must not duplicate on app open)', () {
      final entries = engine.computeForPlanBlock(
        planBlock(hour: 7, minute: 0),
        planItem('plan-1'),
        makePlan(
          startedAt: DateTime(2026, 6, 1),
          totalDays: 30,
        ),
        // 09:00 — past the 07:00 block time, normally triggers a catch-up.
        DateTime(2026, 6, 5, 9),
        masterOn: true,
        routineOn: true,
        seriesScheduledTodayByOS: true,
      );
      expect(entries.any((e) => e.isImmediate), isFalse);
      // Future days must still be scheduled — only the catch-up is suppressed.
      expect(entries, isNotEmpty);
      expect(entries.every((e) => e.fireAt != null), isTrue);
    });
  });

  // ─── Global cap (iOS 64-pending limit) ─────────────────────────────────────

  group('global cap', () {
    DesiredNotification dated(int id, DateTime fireAt) => DesiredNotification(
          id: id,
          fireAt: tz.TZDateTime.from(fireAt, tz.local),
          title: 't',
          body: 'b',
          payload: null,
          sourceItem: null,
          debugCase: '3b',
        );

    test('keeps daily repeats and the soonest dated entries', () {
      final desired = <int, DesiredNotification>{};
      // One recitation daily-repeat — must always survive.
      desired[5555] = DesiredNotification(
        id: 5555,
        fireAt: tz.TZDateTime.from(DateTime(2026, 6, 6, 7), tz.local),
        title: 'r',
        body: 'b',
        payload: null,
        sourceItem: null,
        isDailyRepeat: true,
        debugCase: '4 daily-repeat',
      );
      // 70 dated entries — more than the budget allows.
      for (var day = 1; day <= 70; day++) {
        desired[10000000 + day] = dated(
          10000000 + day,
          DateTime(2026, 6, 5).add(Duration(days: day)),
        );
      }

      engine.applyGlobalCap(desired, (_) {});

      expect(desired[5555], isNotNull, reason: 'daily repeat never dropped');
      final datedLeft =
          desired.values.where((d) => !d.isDailyRepeat).toList();
      expect(
        datedLeft.length,
        NotificationSyncEngine.kMaxTotalScheduled - 1,
        reason: 'budget = cap minus the reserved daily repeat',
      );
      // The survivors are the soonest ones.
      expect(desired.containsKey(10000001), isTrue);
      expect(desired.containsKey(10000070), isFalse);
    });

    test('no-op when under the cap', () {
      final desired = <int, DesiredNotification>{
        for (var day = 1; day <= 10; day++)
          10000000 + day: dated(
            10000000 + day,
            DateTime(2026, 6, 5).add(Duration(days: day)),
          ),
      };
      engine.applyGlobalCap(desired, (_) {});
      expect(desired, hasLength(10));
    });
  });

  // ─── Series routine items ──────────────────────────────────────────────────

  group('computeForSeriesBlock', () {
    RoutineItem seriesItem({String id = 'series-1', String? currentPlanId}) =>
        RoutineItem(
          id: id,
          title: 'My Series',
          type: RoutineItemType.series,
          currentPlanId: currentPlanId,
        );

    test('schedules notifications for the active plan on each upcoming day', () {
      final entries = engine.computeForSeriesBlock(
        planBlock(hour: 9),
        seriesItem(currentPlanId: 'plan-1'),
        [
          makePlan(
            id: 'plan-1',
            startedAt: DateTime(2026, 6, 1),
            totalDays: 30,
          ),
        ],
        DateTime(2026, 6, 5, 8),
        masterOn: true,
        routineOn: true,
      );
      expect(entries, isNotEmpty);
      expect(entries.every((e) => e.enrollmentPlanId == 'plan-1'), isTrue);
      expect(
        entries.any((e) => e.body.contains('Day 5')),
        isTrue,
        reason: 'Jun 5 is day 5 of the plan',
      );
    });

    test('immediate catch-up uses today active plan day', () {
      final entries = engine.computeForSeriesBlock(
        planBlock(hour: 7),
        seriesItem(currentPlanId: 'plan-1'),
        [
          makePlan(
            id: 'plan-1',
            startedAt: DateTime(2026, 6, 1),
            totalDays: 30,
          ),
        ],
        DateTime(2026, 6, 5, 9),
        masterOn: true,
        routineOn: true,
      );
      final immediates = entries.where((e) => e.isImmediate).toList();
      expect(immediates, hasLength(1));
      expect(immediates.first.body, contains('Day 5'));
    });
  });

  // ─── Recitation ────────────────────────────────────────────────────────────

  group('case 4: recitation daily-repeat', () {
    test('emits a single repeating notification when enabled', () {
      final entries = engine.computeForRecitationBlock(
        RoutineBlock(
          id: 'rec-1',
          time: const TimeOfDay(hour: 7, minute: 0),
          notificationEnabled: true,
          items: [recitationItem()],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        recitationOn: true,
      );
      expect(entries, hasLength(1));
      expect(entries.first.isDailyRepeat, isTrue);
      expect(entries.first.debugCase, contains('4'));
    });

    test('emits nothing when recitation sub-toggle OFF', () {
      final entries = engine.computeForRecitationBlock(
        RoutineBlock(
          id: 'rec-1',
          time: const TimeOfDay(hour: 7, minute: 0),
          notificationEnabled: true,
          items: [recitationItem()],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        recitationOn: false,
      );
      expect(entries, isEmpty);
    });
  });

  group('case 4: mala (accumulator) daily-repeat', () {
    RoutineItem malaItem({String id = 'm-1', String title = 'Om Mani Padme Hum'}) =>
        RoutineItem(id: id, title: title, type: RoutineItemType.accumulator);

    test('emits a single repeating notification using the mala title', () {
      final entries = engine.computeForAccumulatorBlock(
        RoutineBlock(
          id: 'mala-1',
          time: const TimeOfDay(hour: 8, minute: 30),
          notificationEnabled: true,
          items: [malaItem()],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        practiceOn: true,
      );
      expect(entries, hasLength(1));
      expect(entries.first.isDailyRepeat, isTrue);
      expect(entries.first.title, 'Om Mani Padme Hum');
      expect(entries.first.id, NotificationIdScheme.accumulatorBlockId(5555));
      expect(entries.first.debugCase, contains('4'));
    });

    test('emits nothing when practice sub-toggle OFF', () {
      final entries = engine.computeForAccumulatorBlock(
        RoutineBlock(
          id: 'mala-1',
          time: const TimeOfDay(hour: 8, minute: 30),
          notificationEnabled: true,
          items: [malaItem()],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        practiceOn: false,
      );
      expect(entries, isEmpty);
    });

    test('ignores non-accumulator items in the block', () {
      final entries = engine.computeForAccumulatorBlock(
        RoutineBlock(
          id: 'mala-1',
          time: const TimeOfDay(hour: 8, minute: 30),
          notificationEnabled: true,
          items: [recitationItem()],
          notificationId: 5555,
        ),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        practiceOn: true,
      );
      expect(entries, isEmpty);
    });
  });

  group('case 4: timer daily-repeats (start + end)', () {
    RoutineItem timerItem({
      String id = 't-1',
      String title = 'Meditation',
      int? durationMs = 1800000, // 30 min
    }) =>
        RoutineItem(
          id: id,
          title: title,
          type: RoutineItemType.timer,
          durationMs: durationMs,
        );

    RoutineBlock timerBlock({
      List<RoutineItem>? items,
      int hour = 8,
      int minute = 30,
    }) =>
        RoutineBlock(
          id: 'timer-1',
          time: TimeOfDay(hour: hour, minute: minute),
          notificationEnabled: true,
          items: items ?? [timerItem()],
          notificationId: 5555,
        );

    test('emits a start reminder and a "timer up" reminder', () {
      final entries = engine.computeForTimerBlock(
        timerBlock(),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        timerOn: true,
      );
      expect(entries, hasLength(2));

      final start = entries[0];
      final end = entries[1];
      expect(start.id, NotificationIdScheme.timerStartId(5555));
      expect(end.id, NotificationIdScheme.timerEndId(5555));
      expect(start.isDailyRepeat, isTrue);
      expect(end.isDailyRepeat, isTrue);
      expect(start.title, 'Meditation');
      expect(end.title, 'Meditation');
      expect(start.body, contains('30 minutes'));
      expect(end.body, 'Your timer is up.');
      // Both reminders deep-link identically; the timer screen syncs its
      // remaining time from the wall clock. Payload embeds the duration and the
      // scheduled minute-of-day (8:30 → 510) so the tap works without
      // re-resolving the routine item.
      for (final payload in [start.payload, end.payload]) {
        expect(payload, contains('durationMs'));
        expect(payload, contains('startMinuteOfDay'));
        expect(payload, contains('510'));
      }
      // Start at block time, end at block time + duration (same day).
      expect(start.fireAt!.hour, 8);
      expect(start.fireAt!.minute, 30);
      expect(end.fireAt!.hour, 9);
      expect(end.fireAt!.minute, 0);
      expect(end.fireAt!.difference(start.fireAt!),
          const Duration(minutes: 30));
    });

    test('rolls both reminders to next day when block time already passed', () {
      final entries = engine.computeForTimerBlock(
        timerBlock(),
        DateTime(2026, 6, 5, 10), // 10:00, block+end (8:30/9:00) already passed
        masterOn: true,
        timerOn: true,
      );
      expect(entries, hasLength(2));
      expect(entries[0].fireAt!.day, 6); // start → tomorrow
      expect(entries[1].fireAt!.day, 6); // end → tomorrow
      expect(entries[0].fireAt!.hour, 8);
      expect(entries[1].fireAt!.hour, 9);
    });

    test('skips today (rolls both to tomorrow) when dismissed today', () {
      // 06:00, block 8:30 is still ahead today — but dismissed, so both roll to
      // tomorrow instead of firing today.
      final entries = engine.computeForTimerBlock(
        timerBlock(),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        timerOn: true,
        isDismissedToday: (_) => true,
      );
      expect(entries, hasLength(2));
      expect(entries[0].fireAt!.day, 6); // start → tomorrow
      expect(entries[1].fireAt!.day, 6); // end → tomorrow
      expect(entries[0].fireAt!.hour, 8);
      expect(entries[1].fireAt!.hour, 9);
    });

    test('emits nothing when master OFF', () {
      final entries = engine.computeForTimerBlock(
        timerBlock(),
        DateTime(2026, 6, 5, 6),
        masterOn: false,
        timerOn: true,
      );
      expect(entries, isEmpty);
    });

    test('emits nothing when timer sub-toggle OFF', () {
      final entries = engine.computeForTimerBlock(
        timerBlock(),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        timerOn: false,
      );
      expect(entries, isEmpty);
    });

    test('emits nothing when duration is null or non-positive', () {
      for (final bad in <int?>[null, 0, -1]) {
        final entries = engine.computeForTimerBlock(
          timerBlock(items: [timerItem(durationMs: bad)]),
          DateTime(2026, 6, 5, 6),
          masterOn: true,
          timerOn: true,
        );
        expect(entries, isEmpty, reason: 'durationMs=$bad');
      }
    });

    test('ignores non-timer items in the block', () {
      final entries = engine.computeForTimerBlock(
        timerBlock(items: [recitationItem()]),
        DateTime(2026, 6, 5, 6),
        masterOn: true,
        timerOn: true,
      );
      expect(entries, isEmpty);
    });
  });

  // ─── ID scheme ─────────────────────────────────────────────────────────────

  group('NotificationIdScheme', () {
    test('isOurs covers all owned ranges', () {
      expect(NotificationIdScheme.isOurs(800), isTrue); // special one-shot
      expect(NotificationIdScheme.isOurs(810), isTrue); // special series
      expect(NotificationIdScheme.isOurs(1500), isTrue); // routine block
      expect(NotificationIdScheme.isOurs(9999), isTrue); // diagnostic
      expect(NotificationIdScheme.isOurs(9000000), isTrue); // plan one-shot
      expect(NotificationIdScheme.isOurs(10000000), isTrue); // plan series
      expect(NotificationIdScheme.isOurs(20000000), isTrue); // accumulator block
      expect(NotificationIdScheme.isOurs(21000000), isTrue); // timer start
      expect(NotificationIdScheme.isOurs(22000000), isTrue); // timer end
      expect(NotificationIdScheme.isOurs(50), isFalse); // system range
      expect(NotificationIdScheme.isOurs(30000000), isFalse); // outside
    });

    test('isRoutineDailyRepeat covers recitation + mala + timer ranges only', () {
      expect(NotificationIdScheme.isRoutineDailyRepeat(5555), isTrue); // recitation block
      expect(
        NotificationIdScheme.isRoutineDailyRepeat(
          NotificationIdScheme.accumulatorBlockId(5555),
        ),
        isTrue, // mala block
      );
      expect(
        NotificationIdScheme.isRoutineDailyRepeat(
          NotificationIdScheme.timerStartId(5555),
        ),
        isTrue, // timer start
      );
      expect(
        NotificationIdScheme.isRoutineDailyRepeat(
          NotificationIdScheme.timerEndId(5555),
        ),
        isTrue, // timer end
      );
      expect(NotificationIdScheme.isRoutineDailyRepeat(9000000), isFalse); // plan one-shot
      expect(NotificationIdScheme.isRoutineDailyRepeat(10000000), isFalse); // plan series
      expect(NotificationIdScheme.isRoutineDailyRepeat(810), isFalse); // special series
    });

    test('accumulator + timer block ids are distinct from each other', () {
      // A block holding a recitation (notificationId), a mala
      // (accumulatorBlockId), and a timer (timerStartId + timerEndId) must
      // produce four non-colliding IDs.
      const blockId = 5555;
      final malaId = NotificationIdScheme.accumulatorBlockId(blockId);
      final timerStart = NotificationIdScheme.timerStartId(blockId);
      final timerEnd = NotificationIdScheme.timerEndId(blockId);
      final ids = {blockId, malaId, timerStart, timerEnd};
      expect(ids, hasLength(4)); // all distinct
      expect(NotificationIdScheme.isOurs(malaId), isTrue);
      expect(NotificationIdScheme.isOurs(timerStart), isTrue);
      expect(NotificationIdScheme.isOurs(timerEnd), isTrue);
    });

    test('special-plan series uses fixed slot per planId', () {
      // ITCC is the first key in kSpecialPlanNotifications — slot 0.
      expect(NotificationIdScheme.specialPlanSeriesId(kItccPlanId, 1), 810);
      expect(NotificationIdScheme.specialPlanSeriesId(kItccPlanId, 6), 815);
    });
  });

  // Silence analyzer warnings for unused imports.
  // Reference the singletons so the static-analysis-only imports are kept.
  test('keeps unused-import warnings down', () {
    expect(RoutineNotificationService(), isNotNull);
    expect(NotificationService(), isNotNull);
  });
}
