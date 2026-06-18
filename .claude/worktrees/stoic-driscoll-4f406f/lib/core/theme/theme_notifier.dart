import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extension that resolves the effective dark/light state of a ThemeMode.
///
/// Never compare `ThemeMode == ThemeMode.dark` directly — that misses
/// `ThemeMode.system` when the OS is in dark mode. Always use [isDark].
extension ThemeModeX on ThemeMode {
  /// Returns true if this mode resolves to a dark UI given [context]'s
  /// platform brightness. Handles [ThemeMode.system] correctly.
  bool isDark(BuildContext context) =>
      this == ThemeMode.dark ||
      (this == ThemeMode.system &&
          MediaQuery.platformBrightnessOf(context) == Brightness.dark);
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final LocalStorageService _localStorageService;

  ThemeModeNotifier({required LocalStorageService localStorageService})
    : _localStorageService = localStorageService,
      super(ThemeMode.system) {
    _loadThemeMode();
  }

  // Load theme mode from local storage if available
  Future<void> _loadThemeMode() async {
    final themeIndex = await _localStorageService.get<int>(
      StorageKeys.themeMode,
    );
    if (themeIndex != null) {
      state = ThemeMode.values[themeIndex];
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _localStorageService.set<int>(StorageKeys.themeMode, mode.index);
  }

  /// Toggles between light and dark. Pass [currentlyDark] from
  /// `themeMode.isDark(context)` so system mode is resolved correctly.
  void toggleTheme({required bool currentlyDark}) {
    setTheme(currentlyDark ? ThemeMode.light : ThemeMode.dark);
  }
}

/// Provider for managing theme mode (light/dark/system)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(
    localStorageService: ref.read(localStorageServiceProvider),
  ),
);
