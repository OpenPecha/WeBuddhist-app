import 'package:flutter_pecha/features/notifications/data/special_plan_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('special_plan_notifications', () {
    final startedAt = DateTime(2026, 1, 1, 9, 0); // Day 1 = 2026-01-01

    group('isSpecialPlan', () {
      test('returns true for ITCC plan id', () {
        expect(isSpecialPlan(kItccPlanId), isTrue);
      });

      test('returns false for unknown plan id', () {
        expect(isSpecialPlan('non-existent-plan-id'), isFalse);
      });
    });

    group('resolveSpecialPlanNotification', () {
      test('returns day-1 content on enrollment day', () {
        final result = resolveSpecialPlanNotification(
          planId: kItccPlanId,
          startedAt: startedAt,
          now: DateTime(2026, 1, 1, 14, 0),
        );
        expect(result, isNotNull);
        expect(result!.title, 'Welcome to the course');
        expect(result.buttonText, isNull);
      });

      test('returns day-2 content one day after enrollment', () {
        final result = resolveSpecialPlanNotification(
          planId: kItccPlanId,
          startedAt: startedAt,
          now: DateTime(2026, 1, 2, 9, 1),
        );
        expect(result, isNotNull);
        expect(result!.title, 'Abhidhamma in a Year');
        expect(result.buttonText, 'START');
      });

      test('returns day-8 content 7 days after enrollment', () {
        final result = resolveSpecialPlanNotification(
          planId: kItccPlanId,
          startedAt: startedAt,
          now: DateTime(2026, 1, 8, 9, 0),
        );
        expect(result, isNotNull);
        expect(result!.title, "You're almost there");
      });

      test('returns null on day 9 (series ended)', () {
        final result = resolveSpecialPlanNotification(
          planId: kItccPlanId,
          startedAt: startedAt,
          now: DateTime(2026, 1, 9, 9, 0),
        );
        expect(result, isNull);
      });

      test('returns null when now is before startedAt (clock skew)', () {
        final result = resolveSpecialPlanNotification(
          planId: kItccPlanId,
          startedAt: startedAt,
          now: DateTime(2025, 12, 31, 23, 59),
        );
        expect(result, isNull);
      });

      test('returns null for non-special plan', () {
        final result = resolveSpecialPlanNotification(
          planId: 'unknown-id',
          startedAt: startedAt,
          now: DateTime(2026, 1, 1),
        );
        expect(result, isNull);
      });

      test('day rollover uses calendar date, not 24h elapsed', () {
        // Enrolled at 23:59 on Jan 1; "now" is 00:01 on Jan 2 — only 2 minutes
        // elapsed but it's a new calendar day → Day 2 content.
        final lateNight = DateTime(2026, 1, 1, 23, 59);
        final earlyMorning = DateTime(2026, 1, 2, 0, 1);
        final result = resolveSpecialPlanNotification(
          planId: kItccPlanId,
          startedAt: lateNight,
          now: earlyMorning,
        );
        expect(result, isNotNull);
        expect(result!.title, 'Abhidhamma in a Year');
      });
    });

    group('isSpecialPlanSeriesEnded', () {
      test('false on enrollment day', () {
        expect(
          isSpecialPlanSeriesEnded(
            planId: kItccPlanId,
            startedAt: startedAt,
            now: DateTime(2026, 1, 1, 9, 0),
          ),
          isFalse,
        );
      });

      test('false on day 8', () {
        expect(
          isSpecialPlanSeriesEnded(
            planId: kItccPlanId,
            startedAt: startedAt,
            now: DateTime(2026, 1, 8, 9, 0),
          ),
          isFalse,
        );
      });

      test('true on day 9', () {
        expect(
          isSpecialPlanSeriesEnded(
            planId: kItccPlanId,
            startedAt: startedAt,
            now: DateTime(2026, 1, 9, 0, 1),
          ),
          isTrue,
        );
      });

      test('false for non-special plan regardless of time', () {
        expect(
          isSpecialPlanSeriesEnded(
            planId: 'unknown',
            startedAt: startedAt,
            now: DateTime(2030, 1, 1),
          ),
          isFalse,
        );
      });
    });

    group('specialPlanDayIndex', () {
      test('returns 1 on enrollment day', () {
        expect(
          specialPlanDayIndex(
            planId: kItccPlanId,
            startedAt: startedAt,
            now: DateTime(2026, 1, 1, 23, 0),
          ),
          1,
        );
      });

      test('returns 5 on day 5', () {
        expect(
          specialPlanDayIndex(
            planId: kItccPlanId,
            startedAt: startedAt,
            now: DateTime(2026, 1, 5, 9, 0),
          ),
          5,
        );
      });

      test('returns null after series ends', () {
        expect(
          specialPlanDayIndex(
            planId: kItccPlanId,
            startedAt: startedAt,
            now: DateTime(2026, 1, 9, 9, 0),
          ),
          isNull,
        );
      });
    });

    group('kSpecialPlanNotifications shape', () {
      test('ITCC has exactly 8 days', () {
        expect(kSpecialPlanNotifications[kItccPlanId]!.length, 8);
      });

      test('every entry has non-empty title and body', () {
        for (final list in kSpecialPlanNotifications.values) {
          for (final entry in list) {
            expect(entry.title, isNotEmpty);
            expect(entry.body, isNotEmpty);
          }
        }
      });
    });
  });
}
