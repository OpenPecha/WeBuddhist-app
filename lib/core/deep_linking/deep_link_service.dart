import 'package:app_links/app_links.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:go_router/go_router.dart';

/// Service to handle incoming deep links from the OS
/// Works with app_links to receive links and go_router to navigate
class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._();
  DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  final _logger = AppLogger('DeepLinkService');
  
  GoRouter? _router;
  Uri? _pendingUri;

  /// Initialize the deep link service
  /// Call this in main() before runApp
  Future<void> initialize() async {
    try {
      // Check for initial link (cold start - app was closed)
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _logger.info('Initial deep link received: $initialUri');
        _pendingUri = initialUri;
        // Will be processed once router is set in MyApp
      }

      // Listen for links while app is running (warm start)
      _appLinks.uriLinkStream.listen(
        (uri) {
          _logger.info('Deep link received while running: $uri');
          _handleDeepLink(uri);
        },
        onError: (error) {
          _logger.error('Error receiving deep link', error);
        },
      );
      
      _logger.info('Deep link service initialized');
    } catch (e) {
      _logger.error('Error initializing deep link service', e);
    }
  }

  /// Set the router instance and process any pending links
  /// Call this in MyApp build method
  void setRouter(GoRouter router) {
    _router = router;
    _logger.info('Router set for deep link service');
    
    // Process pending initial link if any
    if (_pendingUri != null) {
      _logger.info('Processing pending initial link: $_pendingUri');
      _handleDeepLink(_pendingUri!);
      _pendingUri = null;
    }
  }

  /// Handle incoming deep link
  void _handleDeepLink(Uri uri) {
    if (_router == null) {
      _logger.warning('Router not set, storing link for later: $uri');
      _pendingUri = uri;
      return;
    }

    try {
      _logger.info('Processing deep link: $uri');
      _logger.debug('Path: ${uri.path}, Query: ${uri.queryParameters}');

      // Handle different deep link paths
      // Support both HTTPS (path: /plans/invite) and Custom Scheme (host: plans, path: /invite)
      if (uri.path.contains('/plans/invite') || (uri.host == 'plans' && uri.path.contains('/invite'))) {
        _handlePlanInvite(uri);
      } else if (uri.path.contains('/texts')) {
        _handleTextLink(uri);
      } else if (uri.path.contains('/recitations')) {
        _handleRecitationLink(uri);
      } else {
        _logger.warning('Unknown deep link path: ${uri.path}');
        // Fallback to home
        _router!.go('/home');
      }
    } catch (e) {
      _logger.error('Error handling deep link', e);
      // Fallback to home on error
      _router?.go('/home');
    }
  }

  /// Handle plan invitation deep link
  void _handlePlanInvite(Uri uri) {
    final planId = uri.queryParameters['planId'];
    
    if (planId == null || planId.isEmpty) {
      _logger.warning('Plan invite link missing planId parameter');
      _router?.go('/home');
      return;
    }

    _logger.info('Navigating to plan invite: $planId');
    
    // Construct the path correctly - always use /plans/invite
    const routePath = '/plans/invite';
    
    // Navigate to plan info screen with query parameters
    // Build the full path with query string
    final fullPath = '$routePath?planId=${Uri.encodeComponent(planId)}';
    _logger.debug('Navigating to: $fullPath');
    
    // Navigate directly - GoRouter should handle this correctly
    _router?.go(fullPath);
  }

  /// Handle text deep link (for future use)
  void _handleTextLink(Uri uri) {
    final textId = uri.queryParameters['textId'];
    if (textId != null) {
      _logger.info('Navigating to text: $textId');
      _router?.go('/texts/texts?textId=$textId');
    } else {
      _router?.go('/texts/collections');
    }
  }

  /// Handle recitation deep link (for future use)
  void _handleRecitationLink(Uri uri) {
    final recitationId = uri.queryParameters['id'];
    if (recitationId != null) {
      _logger.info('Navigating to recitation: $recitationId');
      // Would need to fetch recitation data first
      _router?.go('/home');
    } else {
      _router?.go('/home');
    }
  }
}
