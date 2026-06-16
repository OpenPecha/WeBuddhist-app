import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:go_router/go_router.dart';

/// Service to handle Airbridge deep links and navigate to appropriate screens
class DeepLinkService {
  static final _logger = AppLogger('DeepLinkService');
  static String? _pendingDeepLink;
  
  /// Store a deep link to be processed later when the app is ready
  static void storePendingDeepLink(String url) {
    _pendingDeepLink = url;
    _logger.info('Stored pending deep link: $url');
  }
  
  /// Process the pending deep link if one exists
  static void processPendingDeepLink(GoRouter router) {
    if (_pendingDeepLink != null) {
      final url = _pendingDeepLink!;
      _pendingDeepLink = null;
      handleDeepLink(url, router);
    }
  }
  
  /// Handle a deep link URL and navigate to the appropriate screen
  static void handleDeepLink(String url, GoRouter router) {
    try {
      _logger.info('Processing deep link: $url');
      
      final uri = Uri.parse(url);
      
      // Handle webuddhist:// scheme
      if (uri.scheme == 'webuddhist') {
        switch (uri.host) {
          case 'home':
            _logger.info('Navigating to home screen');
            router.go(AppRoutes.home);
            break;
            
          case 'practice':
            _logger.info('Navigating to practice screen');
            router.go(AppRoutes.practice);
            break;
            
          case 'texts':
            _logger.info('Navigating to AI mode screen');
            router.go(AppRoutes.texts);
            break;
            
          case 'more':
            _logger.info('Navigating to more screen');
            router.go(AppRoutes.more);
            break;
            
          case 'profile':
            _logger.info('Navigating to profile screen');
            router.go(AppRoutes.profile);
            break;
            
          case 'notifications':
            _logger.info('Navigating to notifications screen');
            router.go(AppRoutes.notifications);
            break;
            
          default:
            _logger.warning('Unknown deep link host: ${uri.host}, defaulting to home');
            router.go(AppRoutes.home);
        }
      } else {
        _logger.warning('Unsupported deep link scheme: ${uri.scheme}');
      }
    } catch (e, stackTrace) {
      _logger.error('Error handling deep link: $e', stackTrace);
    }
  }
}
