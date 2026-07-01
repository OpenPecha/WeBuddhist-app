import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_accumulation_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MalaAccumulationSelectionNotifier
    extends StateNotifier<MalaAccumulationSelection> {
  MalaAccumulationSelectionNotifier(this._presetId)
    : super(const MalaAccumulationSelection.personal()) {
    _load();
  }

  final String _presetId;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      '${StorageKeys.malaAccumulationSelectionPrefix}$_presetId',
    );
    state = MalaAccumulationSelection.fromStorage(raw);
  }

  Future<void> selectPersonal() async {
    state = const MalaAccumulationSelection.personal();
    await _persist();
  }

  Future<void> selectGroup(String groupAccumulatorId) async {
    state = MalaAccumulationSelection.group(groupAccumulatorId);
    await _persist();
  }

  /// Falls back to personal when the saved group is no longer joined.
  Future<void> validateAgainst(List<AccumulatorGroup> groups) async {
    final id = state.groupAccumulatorId;
    if (id == null) return;
    final stillJoined = groups.any((g) => g.groupAccumulatorId == id);
    if (!stillJoined) await selectPersonal();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${StorageKeys.malaAccumulationSelectionPrefix}$_presetId',
      state.toStorage(),
    );
  }
}

final malaAccumulationSelectionProvider = StateNotifierProvider.autoDispose
    .family<MalaAccumulationSelectionNotifier, MalaAccumulationSelection, String>(
      (ref, presetId) => MalaAccumulationSelectionNotifier(presetId),
    );
