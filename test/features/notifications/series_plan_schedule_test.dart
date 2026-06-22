import 'package:flutter_pecha/features/notifications/domain/series_plan_schedule.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserPlansModel plan({
  required String id,
  required DateTime startDate,
  int totalDays = 7,
}) =>
    UserPlansModel(
      id: id,
      title: 'Plan $id',
      description: '',
      language: 'en',
      difficultyLevel: null,
      startedAt: startDate,
      startDate: startDate,
      totalDays: totalDays,
      tags: null,
    );

void main() {
  group('resolveActivePlanForDate', () {
    final planA = plan(
      id: 'a',
      startDate: DateTime(2026, 6, 1),
      totalDays: 5,
    );
    final planB = plan(
      id: 'b',
      startDate: DateTime(2026, 6, 6),
      totalDays: 5,
    );
    final enrolled = [planA, planB];

    test('returns plan active on calendar date', () {
      expect(
        resolveActivePlanForDate(enrolled, DateTime(2026, 6, 3))?.id,
        'a',
      );
      expect(
        resolveActivePlanForDate(enrolled, DateTime(2026, 6, 8))?.id,
        'b',
      );
    });

    test('prefers preferredPlanId when it covers the date', () {
      expect(
        resolveActivePlanForDate(
          enrolled,
          DateTime(2026, 6, 3),
          preferredPlanId: 'b',
        )?.id,
        'a',
        reason: 'falls back when preferred plan does not cover the date',
      );
      expect(
        resolveActivePlanForDate(
          enrolled,
          DateTime(2026, 6, 8),
          preferredPlanId: 'b',
        )?.id,
        'b',
      );
    });

    test('returns null in gap between plans', () {
      expect(resolveActivePlanForDate(enrolled, DateTime(2026, 5, 30)), isNull);
    });
  });

  group('buildUpcomingSeriesSlots', () {
    test('builds slots across sequential plans', () {
      final slots = buildUpcomingSeriesSlots(
        enrolledPlans: [
          plan(id: 'a', startDate: DateTime(2026, 6, 1), totalDays: 3),
          plan(id: 'b', startDate: DateTime(2026, 6, 4), totalDays: 3),
        ],
        now: DateTime(2026, 6, 2, 10),
        maxSlots: 10,
      );
      expect(slots, isNotEmpty);
      expect(slots.first.plan.id, 'a');
      expect(slots.first.dayNumber, 2);
      expect(slots.any((s) => s.plan.id == 'b' && s.dayNumber == 1), isTrue);
    });
  });

  group('isSeriesRoutineItem', () {
    test('true when item id is not an enrolled plan id', () {
      final map = {'plan-1': plan(id: 'plan-1', startDate: DateTime(2026, 1, 1))};
      expect(isSeriesRoutineItem('series-9', map), isTrue);
      expect(isSeriesRoutineItem('plan-1', map), isFalse);
    });
  });
}
