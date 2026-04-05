import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:upgrader/upgrader.dart';

final _logger = AppLogger('AppUpgradeService');

/// Service for checking app updates and launching the app store.
///
/// Uses the upgrader package to check App Store / Play Store for newer versions.
class AppUpgradeService {
  AppUpgradeService._();

  static Upgrader? _upgrader;
  static bool _isInitialized = false;

  /// Initialize the upgrader. Call once at app startup.
  ///
  /// Set [debugDisplayAlways] to true to always show the update banner
  /// for testing purposes, even when no update is available.
  static Future<void> initialize({bool debugDisplayAlways = false}) async {
    if (_isInitialized) return;

    _upgrader = Upgrader(
      countryCode: _getCountryCode(),
      debugLogging: debugDisplayAlways,
      debugDisplayAlways: debugDisplayAlways,
      storeController: UpgraderStoreController(
        onAndroid: () => UpgraderPlayStore(),
        oniOS: () => UpgraderAppStore(),
      ),
    );

    await _upgrader!.initialize();
    _isInitialized = true;
    _logger.info(
      'AppUpgradeService initialized (debugDisplayAlways: $debugDisplayAlways)',
    );
  }

  /// Check if an update is available.
  ///
  /// Returns true if either:
  /// - A real update is available in the store, OR
  /// - debugDisplayAlways is enabled (for testing)
  static Future<bool> isUpdateAvailable() async {
    if (!_isInitialized || _upgrader == null) {
      _logger.warning('AppUpgradeService not initialized');
      return false;
    }

    try {
      // Use shouldDisplayUpgrade() which respects debugDisplayAlways
      final shouldDisplay = _upgrader!.shouldDisplayUpgrade();
      _logger.debug('Should display upgrade: $shouldDisplay');
      return shouldDisplay;
    } catch (e) {
      _logger.error('Error checking for update', e);
      return false;
    }
  }

  /// Open the appropriate app store for the current platform.
  static Future<void> openAppStore() async {
    if (!_isInitialized || _upgrader == null) {
      _logger.warning('AppUpgradeService not initialized, cannot open store');
      return;
    }

    try {
      await _upgrader!.sendUserToAppStore();
      _logger.info('Opened app store');
    } catch (e) {
      _logger.error('Error opening app store', e);
    }
  }

  /// Get the current installed version.
  static String? getCurrentVersion() {
    return _upgrader?.currentInstalledVersion;
  }

  /// Get the app store version (latest available).
  static String? getStoreVersion() {
    return _upgrader?.currentAppStoreVersion;
  }

  /// Gets the country code from user's device locale.
  /// iOS needs explicit country code; Android auto-detects.
  static String? _getCountryCode() {
    if (Platform.isIOS) {
      final locale = ui.PlatformDispatcher.instance.locale;
      final countryCode = locale.countryCode;
      return countryCode?.isNotEmpty == true ? countryCode : 'US';
    }
    return null;
  }
}
