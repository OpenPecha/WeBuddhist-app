import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local group [userTotalCount] values keyed by [AccumulatorGroup.groupAccumulatorId].
///
/// Persisted in Hive per `(userId, groupAccumulatorId)` with `total` /
/// `syncedTotal` dirty tracking. Background sync via [MalaSyncManager].
class GroupAccumulationCountsNotifier extends StateNotifier<Map<String, int>> {
  GroupAccumulationCountsNotifier({
    required Ref ref,
    required MalaLocalDataSource local,
    required MalaSyncManager sync,
    required Future<String?> Function() currentUserId,
  })  : _ref = ref,
        _local = local,
        _sync = sync,
        _currentUserId = currentUserId,
        super(const {}) {
    unawaited(_init());
  }

  final Ref _ref;
  final MalaLocalDataSource _local;
  final MalaSyncManager _sync;
  final Future<String?> Function() _currentUserId;

  String? _userId;

  Future<void> _init() async {
    _userId = await _currentUserId();
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;

    final ids = _local.groupAccumulatorIdsForUser(userId);
    if (ids.isEmpty) return;

    final next = Map<String, int>.from(state);
    for (final id in ids) {
      next[id] = _local.readGroup(userId, id).total;
    }
    state = next;
  }

  /// Reconcile API totals with local Hive state (`max()` on both sides).
  Future<void> mergeFromApi(List<AccumulatorGroup> groups) async {
    if (groups.isEmpty) return;

    var userId = _userId;
    userId ??= await _currentUserId();
    if (userId == null || userId.isEmpty) return;
    _userId = userId;

    final next = Map<String, int>.from(state);
    var changed = false;
    var hasDirtyTail = false;

    for (final group in groups) {
      final id = group.groupAccumulatorId;
      final localState = _local.readGroup(userId, id);
      final total = max(localState.total, group.userTotalCount);
      final syncedTotal = group.userTotalCount;
      final reconciled = localState.copyWith(
        total: total,
        syncedTotal: max(localState.syncedTotal, syncedTotal),
      );

      if (reconciled.total != localState.total ||
          reconciled.syncedTotal != localState.syncedTotal) {
        await _local.writeGroup(userId, id, reconciled);
      }
      if (next[id] != total) {
        next[id] = total;
        changed = true;
      }
      if (reconciled.isDirty) hasDirtyTail = true;
    }

    if (changed) state = next;
    if (hasDirtyTail) unawaited(_sync.flush(SyncReason.launch));
  }

  int countFor(String groupAccumulatorId, List<AccumulatorGroup> groups) {
    final fromState = state[groupAccumulatorId];
    if (fromState != null) return fromState;

    final userId = _userId;
    if (userId != null) {
      final localTotal = _local.readGroup(userId, groupAccumulatorId).total;
      if (localTotal > 0) return localTotal;
    }

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
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;

    final current = countFor(groupAccumulatorId, groups);
    final newTotal = current + 1;
    state = {...state, groupAccumulatorId: newTotal};
    unawaited(_local.recordGroupTap(userId, groupAccumulatorId));

    final roundComplete = newTotal % beadsPerRound == 0;
    if (soundEnabled) {
      _ref.read(malaSoundPlayerProvider).play();
    }
    if (vibrationEnabled) {
      HapticFeedback.lightImpact();
      if (roundComplete) HapticFeedback.mediumImpact();
    }

    _sync.onTap(roundComplete: roundComplete);
  }

  void addRounds({
    required String groupAccumulatorId,
    required List<AccumulatorGroup> groups,
    required int rounds,
    required int beadsPerRound,
  }) {
    if (rounds <= 0) return;

    final userId = _userId;
    if (userId == null || userId.isEmpty) return;

    final current = countFor(groupAccumulatorId, groups);
    final delta = rounds * beadsPerRound;
    final newTotal = current + delta;
    state = {...state, groupAccumulatorId: newTotal};
    unawaited(_local.addGroupToTotal(userId, groupAccumulatorId, delta));
    _sync.onTap(roundComplete: true);
  }
}

final groupAccumulationCountsProvider = StateNotifierProvider.autoDispose
    .family<GroupAccumulationCountsNotifier, Map<String, int>, String>(
  (ref, presetId) => GroupAccumulationCountsNotifier(
    ref: ref,
    local: ref.watch(malaLocalDataSourceProvider),
    sync: ref.watch(malaSyncManagerProvider),
    currentUserId: () => resolveMalaUserId(ref),
  ),
);
