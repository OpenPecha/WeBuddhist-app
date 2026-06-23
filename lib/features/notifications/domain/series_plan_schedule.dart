import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';

/// A calendar date when a series routine item should fire a plan-day notification.
class SeriesPlanNotificationSlot {
  final DateTime calendarDate;
  final UserPlansModel plan;
  final int dayNumber;

  const SeriesPlanNotificationSlot({
    required this.calendarDate,
    required this.plan,
    required this.dayNumber,
  });
}

/// Local-midnight Day 1 anchor for [plan].
DateTime planStartDay(UserPlansModel plan) {
  final anchor = plan.effectiveStartDate;
  return DateTime(anchor.year, anchor.month, anchor.day);
}

/// True when [target] (date-only) falls within [plan]'s active window.
bool planCoversCalendarDate(UserPlansModel plan, DateTime target) {
  final start = planStartDay(plan);
  final end = start.add(Duration(days: plan.totalDays - 1));
  return !target.isBefore(start) && !target.isAfter(end);
}

/// True when [itemId] is a series id (not a direct enrolled plan id).
bool isSeriesRoutineItem(String itemId, Map<String, UserPlansModel> plansById) {
  return !plansById.containsKey(itemId);
}

/// Returns the enrolled plan active on [forDate].
///
/// When several plans overlap, prefers [preferredPlanId] when it covers the
/// date; otherwise picks the plan with the latest start (current segment).
UserPlansModel? resolveActivePlanForDate(
  List<UserPlansModel> enrolledPlans,
  DateTime forDate, {
  String? preferredPlanId,
}) {
  final target = DateTime(forDate.year, forDate.month, forDate.day);
  if (preferredPlanId != null) {
    for (final plan in enrolledPlans) {
      if (plan.id == preferredPlanId && planCoversCalendarDate(plan, target)) {
        return plan;
      }
    }
  }
  UserPlansModel? best;
  DateTime? bestStart;
  for (final plan in enrolledPlans) {
    if (!planCoversCalendarDate(plan, target)) continue;
    final start = planStartDay(plan);
    if (best == null || start.isAfter(bestStart!)) {
      best = plan;
      bestStart = start;
    }
  }
  return best;
}

/// Builds up to [maxSlots] future calendar days that have an active plan in
/// [enrolledPlans], starting from today (local).
List<SeriesPlanNotificationSlot> buildUpcomingSeriesSlots({
  required List<UserPlansModel> enrolledPlans,
  required DateTime now,
  required int maxSlots,
  String? preferredPlanIdForToday,
}) {
  if (enrolledPlans.isEmpty || maxSlots <= 0) return const [];
  final today = DateTime(now.year, now.month, now.day);
  final slots = <SeriesPlanNotificationSlot>[];
  var cursor = today;
  var daysScanned = 0;
  const maxScanDays = 400;
  while (slots.length < maxSlots && daysScanned < maxScanDays) {
    final plan = resolveActivePlanForDate(
      enrolledPlans,
      cursor,
      preferredPlanId: cursor == today ? preferredPlanIdForToday : null,
    );
    if (plan != null) {
      final dayNum = PlanUtils.dayNumberFor(
        plan.effectiveStartDate,
        cursor,
        plan.totalDays,
      );
      if (dayNum >= 1) {
        slots.add(
          SeriesPlanNotificationSlot(
            calendarDate: cursor,
            plan: plan,
            dayNumber: dayNum,
          ),
        );
      }
    }
    cursor = cursor.add(const Duration(days: 1));
    daysScanned++;
  }
  return slots;
}
