import 'dart:convert';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _logger = AppLogger('MalaLocalDataSource');

/// Per-`(userId, presetId)` local counting state.
///
/// Numbers: the monotonic local [total] and the server-confirmed
/// [syncedTotal]. [accumulatorId] is the user-owned accumulator id (null until
/// it has been created on the backend). A background flush only needs the
/// preset id (the Hive key) to create, so nothing else is cached here.
class LocalMalaState {
  const LocalMalaState({
    this.total = 0,
    this.syncedTotal = 0,
    this.accumulatorId,
    this.beadImageUrl,
  });

  final int total;
  final int syncedTotal;
  final String? accumulatorId;

  /// Cached bead-image URL so the strand can render offline on a cold start,
  /// before the seed network call returns.
  final String? beadImageUrl;

  bool get isDirty => total > syncedTotal;

  LocalMalaState copyWith({
    int? total,
    int? syncedTotal,
    String? accumulatorId,
    String? beadImageUrl,
  }) =>
      LocalMalaState(
        total: total ?? this.total,
        syncedTotal: syncedTotal ?? this.syncedTotal,
        accumulatorId: accumulatorId ?? this.accumulatorId,
        beadImageUrl: beadImageUrl ?? this.beadImageUrl,
      );

  Map<String, dynamic> toJson() => {
        'total': total,
        'syncedTotal': syncedTotal,
        if (accumulatorId != null) 'accumulatorId': accumulatorId,
        if (beadImageUrl != null) 'beadImageUrl': beadImageUrl,
      };

  factory LocalMalaState.fromJson(Map<String, dynamic> j) => LocalMalaState(
        total: (j['total'] as num?)?.toInt() ?? 0,
        syncedTotal: (j['syncedTotal'] as num?)?.toInt() ?? 0,
        accumulatorId: j['accumulatorId'] as String?,
        beadImageUrl: j['beadImageUrl'] as String?,
      );
}

/// Hive-backed local store for mala counts, namespaced by user id so one
/// account never reads or sends another's counts. Keys are `userId:presetId`.
class MalaLocalDataSource {
  static const String boxName = 'mala_counts';

  Box<String> get _box => Hive.box<String>(boxName);

  /// Open the box. Call once during app bootstrap (after `Hive.initFlutter()`).
  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<String>(boxName);
      _logger.info('MalaLocalDataSource initialized');
    }
  }

  String _key(String userId, String presetId) => '$userId:$presetId';

  LocalMalaState read(String userId, String presetId) {
    final raw = _box.get(_key(userId, presetId));
    if (raw == null) return const LocalMalaState();
    try {
      return LocalMalaState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      _logger.error('Failed to parse local mala state', e);
      return const LocalMalaState();
    }
  }

  Future<void> write(String userId, String presetId, LocalMalaState s) =>
      _box.put(_key(userId, presetId), jsonEncode(s.toJson()));

  /// Append one recitation to the monotonic local total.
  Future<LocalMalaState> recordTap(String userId, String presetId) async {
    final s = read(userId, presetId);
    final next = s.copyWith(total: s.total + 1);
    await write(userId, presetId, next);
    return next;
  }

  /// Clears the on-screen session after a reset: count back to zero and no
  /// active accumulator id. Preserves [beadImageUrl] for offline rendering.
  Future<void> clearSession(String userId, String presetId) async {
    final s = read(userId, presetId);
    await write(
      userId,
      presetId,
      LocalMalaState(beadImageUrl: s.beadImageUrl),
    );
  }

  /// Preset ids for [userId] whose local total is ahead of the server.
  List<String> dirtyPresetIds(String userId) {
    final prefix = '$userId:';
    return _box.keys
        .cast<String>()
        .where((k) => k.startsWith(prefix))
        .where((k) {
          final raw = _box.get(k);
          if (raw == null) return false;
          try {
            return LocalMalaState.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            ).isDirty;
          } catch (_) {
            return false;
          }
        })
        .map((k) => k.substring(prefix.length))
        .toList();
  }

  /// Remove fully-synced entries for [userId] (storage hygiene on shared
  /// devices). Dirty entries are retained so no unsynced tail is lost.
  Future<void> pruneSynced(String userId) async {
    final prefix = '$userId:';
    final toDelete = _box.keys.cast<String>().where((k) {
      if (!k.startsWith(prefix)) return false;
      final raw = _box.get(k);
      if (raw == null) return true;
      try {
        return !LocalMalaState.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        ).isDirty;
      } catch (_) {
        return true;
      }
    }).toList();
    await _box.deleteAll(toDelete);
  }
}
