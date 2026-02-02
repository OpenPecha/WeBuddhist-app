import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routineProvider =
    StateNotifierProvider<RoutineNotifier, RoutineData>((ref) {
  return RoutineNotifier();
});

class RoutineNotifier extends StateNotifier<RoutineData> {
  RoutineNotifier() : super(const RoutineData());

  void saveRoutine(List<RoutineBlock> blocks) {
    state = RoutineData(blocks: blocks);
  }

  void clearRoutine() {
    state = const RoutineData();
  }
}
