library;

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class AppShareService {
  final _logger = AppLogger('AppShareService');

  /// Airbridge tracking link that handles attribution and deep linking
  /// This link automatically redirects to the appropriate app store
  /// and tracks install/re-engagement conversions
  /// Airbridge provides the link preview with images and metadata
  static const String _airbridgeTrackingLink = 'https://abr.ge/dsw7tl';

  Future<void> shareApp() async {
    try {
      _logger.info('Sharing WeBuddhist app with Airbridge tracking link');

      await SharePlus.instance.share(
        ShareParams(
          text: _airbridgeTrackingLink,
        ),
      );

      _logger.info('App share completed successfully');
    } catch (e) {
      _logger.error('Error sharing app', e);
      rethrow;
    }
  }
}

final appShareServiceProvider = Provider<AppShareService>((ref) {
  return AppShareService();
});
