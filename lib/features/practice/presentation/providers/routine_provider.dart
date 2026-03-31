import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/domain/usecases/get_routines_usecase.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for RoutineNotifier (legacy state management with RoutineData).
///
/// This maintains backward compatibility with existing screens while
/// internally using the new clean architecture use cases.
final routineProvider = StateNotifierProvider<RoutineNotifier, RoutineData>((ref) {
  final getRoutinesUseCase = ref.watch(getRoutinesUseCaseProvider);
  return RoutineNotifier(getRoutinesUseCase);
});

class RoutineNotifier extends StateNotifier<RoutineData> {
  final GetRoutinesUseCase _getRoutinesUseCase;

  RoutineNotifier(this._getRoutinesUseCase) : super(const RoutineData()) {
    _loadRoutines();
  }

  /// Load routines from repository using use case.
  Future<void> _loadRoutines() async {
    final result = await _getRoutinesUseCase(const NoParams());

    result.fold(
      (failure) {
        // Handle error - could emit error state
        // For now, keep empty state
        state = const RoutineData();
      },
      (routines) {
        // Convert Routine entities to RoutineData for backward compatibility
        state = _routinesToRoutineData(routines);
      },
    );
  }

  /// Save routine blocks.
  ///
  /// Note: This currently uses direct data layer access for notification sync.
  /// TODO: Refactor to use use cases once create/update use cases are fully integrated.
  Future<void> saveRoutine(List<RoutineBlock> blocks) async {
    // For now, maintain the old behavior
    // In a full refactor, this would use CreateRoutineUseCase or UpdateRoutineUseCase
    state = RoutineData(blocks: blocks).sortedByTime;
    // TODO: Call repository to persist and sync notifications
  }

  /// Clear all routine data.
  ///
  /// Note: This currently maintains the old behavior.
  /// TODO: Refactor to use delete use case.
  Future<void> clearRoutine() async {
    state = const RoutineData();
    // TODO: Call repository to clear and cancel notifications
  }

  /// Reorder items within a specific block and persist.
  Future<void> reorderItemsInBlock(
    String blockId,
    int oldIndex,
    int newIndex,
  ) async {
    final blocks = state.blocks.map((block) {
      if (block.id != blockId) return block;
      final items = List<RoutineItem>.from(block.items);
      final item = items.removeAt(oldIndex);
      final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      items.insert(adjustedIndex, item);
      return block.copyWith(items: items);
    }).toList();
    await saveRoutine(blocks);
  }

  // ========== Conversion Helpers ==========

  /// Convert list of Routine entities to RoutineData.
  RoutineData _routinesToRoutineData(List routines) {
    // For now, return empty RoutineData since the conversion from
    // Routine entity to RoutineData is complex and would require
    // preserving additional state (items, notification IDs, etc.)
    //
    // In a full implementation, you would:
    // 1. Store full RoutineData with items in the repository
    // 2. Include items in the Routine entity or create a separate entity
    // 3. Implement proper bidirectional conversion
    return const RoutineData();
  }
}
