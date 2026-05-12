import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global on/off for the dual-slot reader layout. Persisted because it's a
/// stable UX preference ("I usually want a translation underneath").
class ReaderSecondaryEnabledNotifier extends StateNotifier<bool> {
  ReaderSecondaryEnabledNotifier({required LocalStorageService localStorage})
      : _storage = localStorage,
        super(false) {
    _loadFuture = _load();
  }

  final LocalStorageService _storage;
  late final Future<void> _loadFuture;

  /// Resolves once the persisted value has been read (or determined absent).
  Future<void> get loaded => _loadFuture;

  Future<void> _load() async {
    final stored = await _storage.get<bool>(
      StorageKeys.readerSecondaryEnabled,
    );
    if (stored == null || !mounted) return;
    state = stored;
  }

  void setEnabled(bool enabled) {
    if (state == enabled) return;
    state = enabled;
    _storage.set<bool>(StorageKeys.readerSecondaryEnabled, enabled);
  }
}

final readerSecondaryEnabledProvider =
    StateNotifierProvider<ReaderSecondaryEnabledNotifier, bool>((ref) {
  return ReaderSecondaryEnabledNotifier(
    localStorage: ref.read(localStorageServiceProvider),
  );
});

/// Per-text dual-slot settings (the toggle + both slot configs).
///
/// `secondaryEnabled` is mirrored from the global
/// [readerSecondaryEnabledProvider] so toggling it persists once and is
/// observed by every text consistently.
///
/// `primary` and `secondary` slot picks live in memory only because their
/// `versionId` / `scriptId` are scoped to a specific text and cannot
/// meaningfully transfer to another text. autoDispose ensures they reset
/// the next time this text is opened.
class ReaderDualSettingsNotifier extends StateNotifier<ReaderDualLayoutSettings> {
  ReaderDualSettingsNotifier({required Ref ref})
      : _ref = ref,
        super(ReaderDualLayoutSettings.initial()) {
    _ref.listen<bool>(
      readerSecondaryEnabledProvider,
      (_, enabled) {
        if (!mounted) return;
        if (state.secondaryEnabled == enabled) return;
        state = state.copyWith(secondaryEnabled: enabled);
      },
      fireImmediately: true,
    );
  }

  final Ref _ref;

  void setSecondaryEnabled(bool enabled) {
    _ref.read(readerSecondaryEnabledProvider.notifier).setEnabled(enabled);
  }

  void replacePrimary(ReaderSlotConfig config) {
    state = state.copyWith(primary: config);
  }

  void replaceSecondary(ReaderSlotConfig config) {
    state = state.copyWith(secondary: config);
  }

  void updatePrimary(
    ReaderSlotConfig Function(ReaderSlotConfig current) update,
  ) {
    state = state.copyWith(primary: update(state.primary));
  }

  void updateSecondary(
    ReaderSlotConfig Function(ReaderSlotConfig current) update,
  ) {
    state = state.copyWith(secondary: update(state.secondary));
  }
}

final readerDualSettingsProvider = StateNotifierProvider.autoDispose
    .family<ReaderDualSettingsNotifier, ReaderDualLayoutSettings, String>(
  (ref, _) => ReaderDualSettingsNotifier(ref: ref),
);
