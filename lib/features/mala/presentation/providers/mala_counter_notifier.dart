import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/usecases/mala_usecases.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_pecha/features/mala/presentation/services/mala_sound_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MalaCounterState {
  const MalaCounterState({
    this.total = 0,
    this.beadsPerRound = kBeadsPerRound,
    this.isSeeding = true,
    this.seedFailed = false,
    this.beadImageUrl,
  });

  final int total;
  final int beadsPerRound;

  /// Per-user bead artwork from the accumulator detail. Null falls back to the
  /// preset/mantra image (see the screen's `?? mantra.beadImageUrl`).
  final String? beadImageUrl;

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
    String? beadImageUrl,
  }) =>
      MalaCounterState(
        total: total ?? this.total,
        beadsPerRound: beadsPerRound ?? this.beadsPerRound,
        isSeeding: isSeeding ?? this.isSeeding,
        seedFailed: seedFailed ?? this.seedFailed,
        beadImageUrl: beadImageUrl ?? this.beadImageUrl,
      );
}

/// Per-mantra monotonic counter. Seeds from the server before enabling taps,
/// then only ever increments. Persists every tap to Hive immediately and pings
/// the app-scoped [MalaSyncManager] for background sync.
class MalaCounterNotifier extends StateNotifier<MalaCounterState> {
  MalaCounterNotifier({
    required Mantra mantra,
    required MalaLocalDataSource local,
    required GetAccumulatorDetailUseCase getAccumulatorDetail,
    required DeleteUserAccumulatorUseCase deleteUserAccumulator,
    required MalaSyncManager sync,
    required Future<String?> Function() currentUserId,
    AnalyticsService? analytics,
    MalaSoundPlayer? sound,
  })  : _mantra = mantra,
        _local = local,
        _getAccumulatorDetail = getAccumulatorDetail,
        _deleteUserAccumulator = deleteUserAccumulator,
        _sync = sync,
        _currentUserId = currentUserId,
        _analytics = analytics,
        _sound = sound,
        super(MalaCounterState(beadsPerRound: mantra.beadsPerRound)) {
    seed();
  }

  final Mantra _mantra;
  final MalaLocalDataSource _local;
  final GetAccumulatorDetailUseCase _getAccumulatorDetail;
  final DeleteUserAccumulatorUseCase _deleteUserAccumulator;
  final MalaSyncManager _sync;
  final Future<String?> Function() _currentUserId;
  final AnalyticsService? _analytics;
  final MalaSoundPlayer? _sound;

  final _logger = AppLogger('MalaCounterNotifier');

  /// The user id resolved during a successful seed. Cached so the synchronous
  /// [incrementBead] can persist taps without re-resolving — taps are blocked
  /// until seeding completes, so this is always set by the time it's read.
  String? _userId;

  String get _presetId => _mantra.presetId;

  /// Fetch the server total and seed local before allowing any taps.
  Future<void> seed() async {
    state = state.copyWith(isSeeding: true, seedFailed: false);

    final userId = await _currentUserId();
    if (!mounted) return; // screen left mid-seed
    if (userId == null || userId.isEmpty) {
      // Not authenticated — the route is login-gated, so treat as transient.
      state = state.copyWith(isSeeding: true, seedFailed: true);
      return;
    }
    _userId = userId;

    // Surface the cached bead image right away so the strand renders correctly
    // offline / before the network seed returns.
    final cachedImage = _local.read(userId, _presetId).beadImageUrl;
    if (cachedImage != null && cachedImage.isNotEmpty) {
      state = state.copyWith(beadImageUrl: cachedImage);
    }

    final result = await _getAccumulatorDetail(_presetId);
    if (!mounted) return; // screen left mid-seed
    result.fold(
      (failure) {
        _logger.warning('Seed failed: ${failure.message}');
        // Prefer blocking with a retry over risking a low send.
        state = state.copyWith(isSeeding: true, seedFailed: true);
      },
      (detail) {
        // detail.accumulatorId is null when the user has no accumulator yet.
        final serverTotal = detail.total;
        final serverAccId = detail.accumulatorId;

        final localState = _local.read(userId, _presetId);
        final total = max(localState.total, serverTotal);

        _local.write(
          userId,
          _presetId,
          localState.copyWith(
            total: total,
            syncedTotal: serverTotal,
            accumulatorId: serverAccId ?? localState.accumulatorId,
            beadImageUrl: detail.beadImageUrl,
          ),
        );

        state = state.copyWith(
          total: total,
          isSeeding: false,
          seedFailed: false,
          beadImageUrl: detail.beadImageUrl,
        );

        // Push any offline tail captured before this seed.
        if (total > serverTotal) _sync.flush(SyncReason.launch);
      },
    );
  }

  /// +1 recitation. No-op while seeding. Monotonic — never decrements.
  void incrementBead({
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) {
    if (state.isSeeding) return;

    final userId = _userId;
    if (userId == null || userId.isEmpty) return;

    final newTotal = state.total + 1;
    final roundComplete = newTotal % state.beadsPerRound == 0;

    state = state.copyWith(total: newTotal);
    _local.recordTap(userId, _presetId);

    if (soundEnabled) _sound?.play();
    if (vibrationEnabled) {
      HapticFeedback.lightImpact();
      if (roundComplete) HapticFeedback.mediumImpact();
    }
    if (roundComplete) {
      _analytics?.track(
        AnalyticsEvents.malaRoundCompleted,
        properties: {'accumulatorId': _presetId, 'rounds': state.rounds},
      );
    }

    _sync.onTap(roundComplete: roundComplete);
  }

  /// Resets the on-screen session to zero by soft-deleting the active server
  /// accumulator (`DELETE /accumulators/user/{id}`). Unsynced taps are flushed
  /// first. Returns false on failure.
  Future<bool> resetCount() async {
    if (state.isSeeding) return false;

    final userId = _userId;
    if (userId == null || userId.isEmpty) return false;

    try {
      await _sync.resetAccumulator(
        _presetId,
        deleteAccumulator: _deleteUserAccumulator,
      );
      if (!mounted) return false;
      final localState = _local.read(userId, _presetId);
      state = state.copyWith(
        total: 0,
        beadImageUrl: localState.beadImageUrl ?? state.beadImageUrl,
      );
      return true;
    } catch (e, st) {
      _logger.warning('Reset failed: $e', e, st);
      return false;
    }
  }

  @override
  void dispose() {
    // Best-effort flush of this mantra's tail as the screen leaves.
    _sync.flush(SyncReason.screenLeave);
    super.dispose();
  }
}
