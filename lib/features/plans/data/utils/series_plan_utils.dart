import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';

/// Helpers for series-scoped plan behavior (ordering, preview windows, etc.).
class SeriesPlanUtils {
  SeriesPlanUtils._();

  /// Number of plan days unlocked on the first plan in a series so users can
  /// preview content before those calendar days arrive.
  static const firstPlanPreviewDayCount = 10;

  static List<Plan> sortPlansByDisplayOrder(List<Plan> plans) {
    return [...plans]..sort((a, b) {
      if (a.displayOrder != null && b.displayOrder != null) {
        return a.displayOrder!.compareTo(b.displayOrder!);
      }
      if (a.displayOrder != null) return -1;
      if (b.displayOrder != null) return 1;
      return 0;
    });
  }

  static Plan? firstPlanInSeries(Series series) {
    if (series.plans.isEmpty) return null;
    return sortPlansByDisplayOrder(series.plans).first;
  }

  static bool isFirstPlanInAnySeries(String planId, Iterable<Series> seriesList) {
    for (final series in seriesList) {
      if (firstPlanInSeries(series)?.id == planId) return true;
    }
    return false;
  }

  static int previewUnlockDayCountForPlan(
    String planId, {
    Series? series,
    Iterable<Series>? seriesList,
  }) {
    if (series != null &&
        isFirstPlanInAnySeries(planId, [series])) {
      return firstPlanPreviewDayCount;
    }
    if (seriesList != null &&
        isFirstPlanInAnySeries(planId, seriesList)) {
      return firstPlanPreviewDayCount;
    }
    return 0;
  }
}
