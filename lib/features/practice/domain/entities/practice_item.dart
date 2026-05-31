import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';

/// Domain-level item shown in the practice picker. Either a standalone [Plan]
/// or a [Series]. Callers branch on the subtype rather than a discriminator
/// string so unknown server `type` values are filtered out upstream.
sealed class PracticeItem {
  /// Shared id used for routine duplicate-detection and enrolled-series
  /// filtering across plan and series rows.
  String get id;
}

class PracticePlanItem implements PracticeItem {
  final Plan plan;
  const PracticePlanItem(this.plan);

  @override
  String get id => plan.id;
}

class PracticeSeriesItem implements PracticeItem {
  final Series series;
  const PracticeSeriesItem(this.series);

  @override
  String get id => series.id;
}
