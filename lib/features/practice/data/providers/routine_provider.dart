import 'package:flutter_pecha/features/practice/data/datasources/routine_local_storage.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/services/routine_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for RoutineLocalStorage — must be overridden in ProviderScope
/// with an initialized instance from main.dart.
final routineLocalStorageProvider = Provider<RoutineLocalStorage>((ref) {
  throw UnimplementedError(
    'routineLocalStorageProvider must be overridden in ProviderScope',
  );
});

final routineProvider =
    StateNotifierProvider<RoutineNotifier, RoutineData>((ref) {
  final storage = ref.watch(routineLocalStorageProvider);
  return RoutineNotifier(storage);
});

class RoutineNotifier extends StateNotifier<RoutineData> {
  final RoutineLocalStorage _storage;
  final RoutineNotificationService _notificationService =
      RoutineNotificationService();

  RoutineNotifier(this._storage) : super(const RoutineData()) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final data = _storage.loadRoutine();
    state = data.sortedByTime;
  }

  /// Save blocks, persist to Hive, sort by time, and sync notifications.
  Future<void> saveRoutine(List<RoutineBlock> blocks) async {
    final data = RoutineData(blocks: blocks).sortedByTime;
    state = data;
    await _storage.saveRoutine(data);
    await _notificationService.syncNotifications(data.blocks);
  }

  /// Clear all routine data, cancel notifications, and delete from Hive.
  Future<void> clearRoutine() async {
    await _notificationService.cancelAllBlockNotifications(state.blocks);
    state = const RoutineData();
    await _storage.clearRoutine();
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
}
