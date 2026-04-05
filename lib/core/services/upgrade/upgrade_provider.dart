import 'package:flutter_pecha/core/services/upgrade/app_upgrade_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('UpgradeProvider');

/// Provider that checks if an app update is available.
///
/// Returns `true` if a newer version is available in the app store.
/// This is a FutureProvider that initializes the upgrade service and checks once.
///
/// **For Testing:**
/// Set `debugDisplayAlways` to `true` to always show the update banner,
/// even when no actual update is available.
final updateAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    // Set to true to test the update banner UI
    const debugDisplayAlways = false;

    await AppUpgradeService.initialize(debugDisplayAlways: debugDisplayAlways);
    final isAvailable = await AppUpgradeService.isUpdateAvailable();
    _logger.info('Update check complete. Available: $isAvailable');
    return isAvailable;
  } catch (e) {
    _logger.error('Error in updateAvailableProvider', e);
    return false;
  }
});

/// Provider to trigger opening the app store.
/// Call `ref.read(openAppStoreProvider)` to open the store.
final openAppStoreProvider = Provider<void Function()>((ref) {
  return () {
    AppUpgradeService.openAppStore();
  };
});

/// Tracks whether the update banner has been shown in this app session.
/// Once shown (and auto-dismissed), it won't show again until app restart.
final updateBannerShownProvider = StateProvider<bool>((ref) => false);
