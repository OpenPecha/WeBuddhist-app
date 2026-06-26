import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';

/// Sealed class representing a session selection result.
/// Used as return type from SelectSessionScreen for type-safe handling.
sealed class SessionSelection {
  const SessionSelection();
}

/// Represents a plan selection from the session picker.
/// Uses the domain entity [Plan] following Clean Architecture principles.
class PlanSessionSelection extends SessionSelection {
  final Plan plan;

  const PlanSessionSelection(this.plan);
}

/// Represents a recitation selection from the session picker.
class RecitationSessionSelection extends SessionSelection {
  final RecitationModel recitation;

  const RecitationSessionSelection(this.recitation);
}

/// Represents a series selection from the session picker.
///
/// The full [series] entity is carried (not just the id) so the consumer can
/// display the series name in transient UI (snackbars/loaders) without an
/// extra fetch. Enrollment + plan injection are handled downstream by
/// reusing the existing `seriesEnrollmentProvider` + `enrollSeriesId`
/// handoff to `EditRoutineScreen`.
class SeriesSessionSelection extends SessionSelection {
  final Series series;

  const SeriesSessionSelection(this.series);

  String get seriesId => series.id;
}

/// Represents a timer selection — carries the full [PresetTimer] entity so
/// the routine screen can build the item without an extra fetch.
class TimerSessionSelection extends SessionSelection {
  final PresetTimer timer;

  const TimerSessionSelection(this.timer);
}
