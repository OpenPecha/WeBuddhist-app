import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('GroupAccumulationCountsNotifier');

/// Local group [userTotalCount] values keyed by [AccumulatorGroup.groupAccumulatorId].
///
/// Seeded from the groups API and incremented when the user counts while a group
/// is selected. Syncs absolute totals via `POST /group-accumulators/{id}`.
class GroupAccumulationCountsNotifier extends StateNotifier<Map<String, int>> {
  GroupAccumulationCountsNotifier(this._ref) : super(const {});

  final Ref _ref;

  void mergeFromApi(List<AccumulatorGroup> groups) {
    if (groups.isEmpty) return;
    final next = Map<String, int>.from(state);
    var changed = false;
    for (final group in groups) {
      final id = group.groupAccumulatorId;
      final merged = _maxCount(next[id], group.userTotalCount);
      if (merged != next[id]) {
        next[id] = merged;
        changed = true;
      }
    }
    if (changed) state = next;
  }

  int countFor(String groupAccumulatorId, List<AccumulatorGroup> groups) {
    final local = state[groupAccumulatorId];
    if (local != null) return local;
    for (final group in groups) {
      if (group.groupAccumulatorId == groupAccumulatorId) {
        return group.userTotalCount;
      }
    }
    return 0;
  }

  void increment({
    required String groupAccumulatorId,
    required List<AccumulatorGroup> groups,
    required bool soundEnabled,
    required bool vibrationEnabled,
    required int beadsPerRound,
  }) {
    final current = countFor(groupAccumulatorId, groups);
    final newTotal = current + 1;
    state = {...state, groupAccumulatorId: newTotal};

    final roundComplete = newTotal % beadsPerRound == 0;
    if (soundEnabled) {
      _ref.read(malaSoundPlayerProvider).play();
    }
    if (vibrationEnabled) {
      HapticFeedback.lightImpact();
      if (roundComplete) HapticFeedback.mediumImpact();
    }

    _syncCount(groupAccumulatorId, newTotal);
  }

  Future<void> _syncCount(String groupAccumulatorId, int currentCount) async {
    final result = await _ref
        .read(malaRepositoryProvider)
        .submitGroupAccumulatorCount(
          groupAccumulatorId: groupAccumulatorId,
          currentCount: currentCount,
        );
    result.fold(
      (failure) => _logger.warning(
        'Failed to sync group count ($groupAccumulatorId): ${failure.message}',
      ),
      (_) {},
    );
  }

  int _maxCount(int? a, int b) {
    if (a == null) return b;
    return a > b ? a : b;
  }
}

final groupAccumulationCountsProvider = StateNotifierProvider.autoDispose
    .family<GroupAccumulationCountsNotifier, Map<String, int>, String>(
      (ref, presetId) => GroupAccumulationCountsNotifier(ref),
    );
