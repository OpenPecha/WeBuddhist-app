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
        type: RoutineItemType.plan,
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
        imageUrl: null,
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

  // ─── ID scheme ─────────────────────────────────────────────────────────────

  group('NotificationIdScheme', () {
    test('isOurs covers all owned ranges', () {
      expect(NotificationIdScheme.isOurs(800), isTrue); // special one-shot
      expect(NotificationIdScheme.isOurs(810), isTrue); // special series
      expect(NotificationIdScheme.isOurs(1500), isTrue); // routine block
      expect(NotificationIdScheme.isOurs(9999), isTrue); // diagnostic
      expect(NotificationIdScheme.isOurs(9000000), isTrue); // plan one-shot
      expect(NotificationIdScheme.isOurs(10000000), isTrue); // plan series
      expect(NotificationIdScheme.isOurs(50), isFalse); // system range
      expect(NotificationIdScheme.isOurs(20000000), isFalse); // outside
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
