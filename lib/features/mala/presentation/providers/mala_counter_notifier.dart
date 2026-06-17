import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/usecases/mala_usecases.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MalaCounterState {
  const MalaCounterState({
    this.total = 0,
    this.beadsPerRound = kBeadsPerRound,
    this.isSeeding = true,
    this.seedFailed = false,
  });

  final int total;
  final int beadsPerRound;

  /// True until the server seed completes — taps are blocked while seeding.
  final bool isSeeding;

  /// Seed could not reach the server; show a retry affordance, keep blocking.
  final bool seedFailed;

  int get beadInRound => total % beadsPerRound;

  /// Completed rounds: 0 at start, 1 only once the 108th bead lands.
  int get rounds => total ~/ beadsPerRound;

  MalaCounterState copyWith({
    int? total,
    int? beadsPerRound,
    bool? isSeeding,
    bool? seedFailed,
  }) =>
      MalaCounterState(
        total: total ?? this.total,
        beadsPerRound: beadsPerRound ?? this.beadsPerRound,
        isSeeding: isSeeding ?? this.isSeeding,
        seedFailed: seedFailed ?? this.seedFailed,
      );
}

/// Per-mantra monotonic counter. Seeds from the server before enabling taps,
/// then only ever increments. Persists every tap to Hive immediately and pings
/// the app-scoped [MalaSyncManager] for background sync.
class MalaCounterNotifier extends StateNotifier<MalaCounterState> {
  MalaCounterNotifier({
    required Mantra mantra,
    required MalaLocalDataSource local,
    required GetUserTotalsUseCase getUserTotals,
    required MalaSyncManager sync,
    required String? Function() currentUserId,
    AnalyticsService? analytics,
  })  : _mantra = mantra,
        _local = local,
        _getUserTotals = getUserTotals,
        _sync = sync,
        _currentUserId = currentUserId,
        _analytics = analytics,
        super(MalaCounterState(beadsPerRound: mantra.beadsPerRound)) {
    seed();
  }

  final Mantra _mantra;
  final MalaLocalDataSource _local;
  final GetUserTotalsUseCase _getUserTotals;
  final MalaSyncManager _sync;
  final String? Function() _currentUserId;
  final AnalyticsService? _analytics;

  final _logger = AppLogger('MalaCounterNotifier');

  String get _presetId => _mantra.presetId;

  /// Fetch the server total and seed local before allowing any taps.
  Future<void> seed() async {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      // Not authenticated — the route is login-gated, so treat as transient.
      state = state.copyWith(isSeeding: true, seedFailed: true);
      return;
    }
    state = state.copyWith(isSeeding: true, seedFailed: false);

    final result = await _getUserTotals(const NoParams());
    if (!mounted) return; // screen left mid-seed
    result.fold(
      (failure) {
        _logger.warning('Seed failed: ${failure.message}');
        // Prefer blocking with a retry over risking a low send.
        state = state.copyWith(isSeeding: true, seedFailed: true);
      },
      (totals) {
        MalaCount? match;
        for (final t in totals) {
          if (_matches(t)) {
            match = t;
            break;
          }
        }
        final serverTotal = match?.total ?? 0;
        final serverAccId = match?.accumulatorId;

        final localState = _local.read(userId, _presetId);
        final total = max(localState.total, serverTotal);

        _local.write(
          userId,
          _presetId,
          localState.copyWith(
            total: total,
            syncedTotal: serverTotal,
            accumulatorId: serverAccId ?? localState.accumulatorId,
            name: _mantra.name,
            mantraId: _mantra.mantraId,
          ),
        );

        state = state.copyWith(
          total: total,
          isSeeding: false,
          seedFailed: false,
        );

        // Push any offline tail captured before this seed.
        if (total > serverTotal) _sync.flush(SyncReason.launch);
      },
    );
  }

  /// A user accumulator belongs to this preset when their mantra ids match.
  bool _matches(MalaCount count) =>
      _mantra.mantraId != null && count.mantraId == _mantra.mantraId;

  /// +1 recitation. No-op while seeding. Monotonic — never decrements.
  void incrementBead() {
    if (state.isSeeding) return;

    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) return;

    final newTotal = state.total + 1;
    final roundComplete = newTotal % state.beadsPerRound == 0;

    state = state.copyWith(total: newTotal);
    _local.recordTap(userId, _presetId);

    HapticFeedback.lightImpact();
    if (roundComplete) {
      HapticFeedback.mediumImpact();
      _analytics?.track(
        AnalyticsEvents.malaRoundCompleted,
        properties: {'accumulatorId': _presetId, 'rounds': state.rounds},
      );
    }

    _sync.onTap(roundComplete: roundComplete);
  }

  @override
  void dispose() {
    // Best-effort flush of this mantra's tail as the screen leaves.
    _sync.flush(SyncReason.screenLeave);
    super.dispose();
  }
}
