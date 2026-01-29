/// Service to handle sharing the WeBuddhist app with friends
library;

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class AppShareService {
  final _logger = AppLogger('AppShareService');

  /// App Store URLs
  static const String _iosAppStoreUrl =
      'https://apps.apple.com/app/webuddhist/id6745810914';
  static const String _androidPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=org.pecha.app';

  /// Generate share message for the app
  String generateShareMessage() {
    return '''I'm using WeBuddhist to learn and practice Buddhism. Join me!

📲 Download:
iOS: $_iosAppStoreUrl
Android: $_androidPlayStoreUrl''';
  }

  /// Share the app with friends
  /// Opens the native share sheet with app download links
  Future<void> shareApp() async {
    try {
      _logger.info('Sharing WeBuddhist app');

      final message = generateShareMessage();

      // Share using native share sheet
      await Share.share(
        message,
        subject: 'Join me on WeBuddhist',
      );

      _logger.info('App share completed successfully');
    } catch (e) {
      _logger.error('Error sharing app', e);
      rethrow;
    }
  }
}

/// Riverpod provider for AppShareService
final appShareServiceProvider = Provider<AppShareService>((ref) {
  return AppShareService();
});
