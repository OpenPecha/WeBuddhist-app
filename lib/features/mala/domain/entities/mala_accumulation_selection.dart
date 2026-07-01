import 'package:equatable/equatable.dart';

/// Which accumulation total the mala counter displays and increments.
sealed class MalaAccumulationSelection extends Equatable {
  const MalaAccumulationSelection();

  const factory MalaAccumulationSelection.personal() =
      PersonalAccumulationSelection;

  factory MalaAccumulationSelection.group(String groupAccumulatorId) {
    return GroupAccumulationSelection(groupAccumulatorId);
  }

  bool get isPersonal => this is PersonalAccumulationSelection;

  String? get groupAccumulatorId =>
      switch (this) {
        PersonalAccumulationSelection() => null,
        GroupAccumulationSelection(id: final id) => id,
      };

  static MalaAccumulationSelection fromStorage(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'personal') {
      return const MalaAccumulationSelection.personal();
    }
    if (raw.startsWith('group:')) {
      final id = raw.substring('group:'.length);
      if (id.isNotEmpty) return MalaAccumulationSelection.group(id);
    }
    return const MalaAccumulationSelection.personal();
  }

  String toStorage() => switch (this) {
    PersonalAccumulationSelection() => 'personal',
    GroupAccumulationSelection(id: final id) => 'group:$id',
  };
}

final class PersonalAccumulationSelection extends MalaAccumulationSelection {
  const PersonalAccumulationSelection();

  @override
  List<Object?> get props => const [];
}

final class GroupAccumulationSelection extends MalaAccumulationSelection {
  const GroupAccumulationSelection(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
