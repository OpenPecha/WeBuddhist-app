import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/usecases/mala_usecases.dart';

enum SyncReason {
  launch,
  tap,
  roundComplete,
  debounce,
  background,
  reconnect,
  screenLeave,
  logout,
}

/// App-scoped background sync for mala counts.
///
/// Sends the **absolute lifetime total** per accumulator (defensive
/// absolute-total model): seed-before-send guarantees a stale low value is
/// never sent, and `max()` on both sides keeps the count monotonic and
/// reconciles across devices. Reads dirty entries straight from Hive, so it
/// flushes even after the user has left the mala screen.
class MalaSyncManager with WidgetsBindingObserver {
  MalaSyncManager({
    required MalaLocalDataSource local,
    required CreateUserAccumulatorUseCase createAccumulator,
    required UpdateUserAccumulatorUseCase updateAccumulator,
    required bool Function() isLoggedIn,
    required Future<String?> Function() currentUserId,
    Stream<bool>? connectivityStream,
    AnalyticsService? analytics,
  })  : _local = local,
        _createAccumulator = createAccumulator,
        _updateAccumulator = updateAccumulator,
        _isLoggedIn = isLoggedIn,
        _currentUserId = currentUserId,
        _connectivityStream = connectivityStream,
        _analytics = analytics;

  final MalaLocalDataSource _local;
  final CreateUserAccumulatorUseCase _createAccumulator;
  final UpdateUserAccumulatorUseCase _updateAccumulator;
  final bool Function() _isLoggedIn;
  final Future<String?> Function() _currentUserId;
  final Stream<bool>? _connectivityStream;
  final AnalyticsService? _analytics;

  final _logger = AppLogger('MalaSyncManager');

  static const Duration _debounceDelay = Duration(seconds: 5);
  static const Duration _maxBackoff = Duration(seconds: 60);

  bool _started = false;
  bool _isSyncing = false;
  bool _dirty = false; // a trigger fired mid-flush; sweep again afterwards
  Timer? _debounce;
  Timer? _retry;
  int _retryAttempt = 0;
  StreamSubscription<bool>? _connectivitySub;

  /// Attach lifecycle + connectivity observers and flush any offline tail.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _connectivitySub = _connectivityStream?.listen((online) {
      if (online) unawaited(flush(SyncReason.reconnect));
    });
    unawaited(flush(SyncReason.launch));
  }

  void dispose() {
    _debounce?.cancel();
    _retry?.cancel();
    _connectivitySub?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  /// Called by the counter notifier on each tap.
  void onTap({required bool roundComplete}) {
    if (roundComplete) {
      _debounce?.cancel();
      unawaited(flush(SyncReason.roundComplete));
    } else {
      _debounce?.cancel();
      _debounce = Timer(_debounceDelay, () => flush(SyncReason.debounce));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(flush(SyncReason.background));
    }
  }

  /// One guarded flush for all triggers. Idempotent: re-sending the same
  /// absolute total is a no-op on the server, so retries are always safe.
  Future<void> flush(SyncReason reason) async {
    if (!_isLoggedIn()) return;
    final userId = await _currentUserId();
    if (userId == null || userId.isEmpty) return;

    if (_isSyncing) {
      _dirty = true; // collapse concurrent triggers
      return;
    }
    _isSyncing = true;
    _debounce?.cancel();

    try {
      for (final presetId in _local.dirtyPresetIds(userId)) {
        final s = _local.read(userId, presetId);
        if (!s.isDirty) continue;

        // First time only: mint the accumulator once via POST {parent_id}.
        // The new accumulator starts at 0; the absolute total is pushed by the
        // PUT below. Thereafter accumulatorId is non-null and we PUT only.
        var accumulatorId = s.accumulatorId;
        if (accumulatorId == null) {
          final created = await _createAccumulator(presetId);
          accumulatorId = created.fold(
            (failure) => throw Exception(failure.message), // keep dirty; retry
            (count) {
              _local.write(
                userId,
                presetId,
                _local.read(userId, presetId).copyWith(
                      accumulatorId: count.accumulatorId,
                    ),
              );
              return count.accumulatorId;
            },
          );
          if (accumulatorId == null) {
            throw Exception('Create returned no accumulator id');
          }
        }

        final sending = s.total; // capture before the network round-trip
        final result = await _updateAccumulator(
          UpdateUserAccumulatorParams(
            accumulatorId: accumulatorId,
            currentCount: sending,
          ),
        );

        result.fold(
          (failure) => throw Exception(failure.message), // keep dirty; retry
          (count) {
            // Re-read: taps may have landed during the round-trip.
            final after = _local.read(userId, presetId);
            _local.write(
              userId,
              presetId,
              after.copyWith(
                total: max(after.total, count.total),
                syncedTotal: max(count.total, sending),
                accumulatorId: count.accumulatorId ?? accumulatorId,
              ),
            );
            _analytics?.track(
              AnalyticsEvents.malaSynced,
              properties: {
                'accumulatorId': count.accumulatorId ?? accumulatorId,
                'total': max(count.total, sending),
              },
            );
          },
        );
      }
      _retryAttempt = 0;
      _retry?.cancel();
    } catch (e) {
      _logger.warning('Mala flush failed ($reason): $e');
      _scheduleRetry();
    } finally {
      _isSyncing = false;
      if (_dirty) {
        _dirty = false;
        unawaited(flush(reason)); // sweep taps that landed mid-flush
      }
    }
  }

  void _scheduleRetry() {
    _retry?.cancel();
    final seconds = min(_maxBackoff.inSeconds, pow(2, _retryAttempt + 1).toInt());
    _retryAttempt++;
    _retry = Timer(Duration(seconds: seconds), () => flush(SyncReason.launch));
  }
}
