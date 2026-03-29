import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/plan_days_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Get plan days by plan id provider
final planDaysByPlanIdFutureProvider =
    FutureProvider.family<List<PlanDaysModel>, String>((ref, planId) {
      final useCase = ref.watch(getPlanDaysUseCaseProvider);
      return useCase(planId);
    });

// Plan days params
class PlanDaysParams {
  final String planId;
  final int dayNumber;
  const PlanDaysParams({required this.planId, required this.dayNumber});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanDaysParams &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          dayNumber == other.dayNumber;

  @override
  int get hashCode => planId.hashCode ^ dayNumber.hashCode;
}

// Get day content with tasks by plan id and day number
final planDayContentFutureProvider =
    FutureProvider.family<PlanDaysModel, PlanDaysParams>((ref, params) {
      final useCase = ref.watch(getDayContentUseCaseProvider);
      return useCase(DayContentParams(
        planId: params.planId,
        dayNumber: params.dayNumber,
      ));
    });
