import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:go_router/go_router.dart';

/// Service to handle Airbridge deep links and navigate to appropriate screens
class DeepLinkService {
  static final _logger = AppLogger('DeepLinkService');
  static String? _pendingDeepLink;

  /// Router reference kept alive after the first build so deep links arriving
  /// while the app is already running can be dispatched immediately.
  static GoRouter? _router;

  /// Called once from the first post-frame callback in MyApp.build().
  /// After this point [_router] is set and [storePendingDeepLink] will
  /// dispatch future links straight to the router without buffering.
  static void setRouter(GoRouter router) {
    _router = router;
    // Drain any link that arrived during cold start before the router existed.
    processPendingDeepLink(router);
  }

  /// Store a deep link to be processed when the router is ready.
  /// If the router is already available (app running), dispatch immediately.
  static void storePendingDeepLink(String url) {
    if (_router != null) {
      _logger.info('Router available, dispatching deep link immediately: $url');
      handleDeepLink(url, _router!);
    } else {
      _pendingDeepLink = url;
      _logger.info('Router not ready, stored pending deep link: $url');
    }
  }

  /// Process the pending deep link if one exists.
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
