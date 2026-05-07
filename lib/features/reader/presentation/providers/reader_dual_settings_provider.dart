import 'dart:async';

import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReaderDualSettingsNotifier extends StateNotifier<ReaderDualLayoutSettings> {
  ReaderDualSettingsNotifier({required LocalStorageService localStorage})
      : _storage = localStorage,
        super(ReaderDualLayoutSettings.initial()) {
    _loadFuture = _load();
  }

  final LocalStorageService _storage;
  Timer? _persistTimer;
  late final Future<void> _loadFuture;

  Future<void> get loaded => _loadFuture;

  Future<void> _load() async {
    final raw = await _storage.get<String>(
      StorageKeys.readerDualSlotPreferences,
    );
    if (raw == null || raw.isEmpty) return;
    if (!mounted) return;
    state = ReaderDualLayoutSettings.decode(raw);
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 250), () {
      _storage.set<String>(
        StorageKeys.readerDualSlotPreferences,
        state.encode(),
      );
    });
  }

  void setSecondaryEnabled(bool enabled) {
    state = state.copyWith(secondaryEnabled: enabled);
    _schedulePersist();
  }

  void updatePrimary(
    ReaderSlotConfig Function(ReaderSlotConfig current) update,
  ) {
    state = state.copyWith(primary: update(state.primary));
    _schedulePersist();
  }

  void updateSecondary(
    ReaderSlotConfig Function(ReaderSlotConfig current) update,
  ) {
    state = state.copyWith(secondary: update(state.secondary));
    _schedulePersist();
  }

  void replacePrimary(ReaderSlotConfig config) {
    state = state.copyWith(primary: config);
    _schedulePersist();
  }

  void replaceSecondary(ReaderSlotConfig config) {
    state = state.copyWith(secondary: config);
    _schedulePersist();
  }

  @override
  void dispose() {
    if (_persistTimer?.isActive ?? false) {
      _persistTimer?.cancel();
      _storage.set<String>(
        StorageKeys.readerDualSlotPreferences,
        state.encode(),
      );
    }
    super.dispose();
  }
}

final readerDualSettingsProvider = StateNotifierProvider<
    ReaderDualSettingsNotifier, ReaderDualLayoutSettings>((ref) {
  return ReaderDualSettingsNotifier(
    localStorage: ref.read(localStorageServiceProvider),
  );
});
