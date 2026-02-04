import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';

/// Sealed class representing a session selection result.
/// Used as return type from SelectSessionScreen for type-safe handling.
sealed class SessionSelection {
  const SessionSelection();
}

/// Represents a plan selection from the session picker.
class PlanSessionSelection extends SessionSelection {
  final PlansModel plan;

  const PlanSessionSelection(this.plan);
}

/// Represents a recitation selection from the session picker.
class RecitationSessionSelection extends SessionSelection {
  final RecitationModel recitation;

  const RecitationSessionSelection(this.recitation);
}
