library;

import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class AppShareService {
  final _logger = AppLogger('AppShareService');

  String buildShareMessage(String localizedMessage) {
    return '$localizedMessage\n\n${AppConfig.airbridgeTrackingLink}';
  }

  Future<void> shareApp(String localizedMessage) async {
    try {
      _logger.info('Sharing WeBuddhist app with Airbridge tracking link');

      await SharePlus.instance.share(
        ShareParams(
          text: buildShareMessage(localizedMessage),
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
