library;

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class AppShareService {
  final _logger = AppLogger('AppShareService');

  static const String _iosAppStoreUrl =
      'https://apps.apple.com/app/webuddhist/id6745810914';
  static const String _androidPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=org.pecha.app';

  String generateShareMessage() {
    return '''I'm using WeBuddhist to learn and practice Buddhism. Join me!

📲 Download:
iOS: $_iosAppStoreUrl
Android: $_androidPlayStoreUrl''';
  }

  Future<void> shareApp() async {
    try {
      _logger.info('Sharing WeBuddhist app');

      final message = generateShareMessage();

      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: 'Join me on WeBuddhist',
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
