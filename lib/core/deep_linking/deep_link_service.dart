import 'package:app_links/app_links.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:go_router/go_router.dart';

/// Listens for incoming Universal Links (iOS) and App Links (Android) and
/// routes the user to the correct screen inside the app.
///
/// Two entry points:
///   • Cold start  — app was closed when the link was tapped.
///   • Warm start  — app was already running in the foreground / background.
///
/// Usage:
///   1. Call [initialize] in main() before runApp.
///   2. Call [setRouter] from MyApp.build() after the router is ready.
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  final _logger = AppLogger('DeepLinkService');

  GoRouter? _router;

  /// URI received on cold start before the router is available.
  Uri? _pendingUri;

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Call once in main(), before runApp.
  Future<void> initialize() async {
    try {
      // Cold-start: app opened via a link tap.
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _logger.info('Cold-start deep link: $initial');
        _pendingUri = initial;
      }

      // Warm-start: link tapped while app is already running.
      _appLinks.uriLinkStream.listen(
        (uri) {
          _logger.info('Warm-start deep link: $uri');
          _handleDeepLink(uri);
        },
        onError: (e) => _logger.error('Deep link stream error', e),
      );

      _logger.info('DeepLinkService initialised');
    } catch (e) {
      _logger.error('DeepLinkService init error', e);
    }
  }

  /// Call from MyApp.build() after the GoRouter instance is available.
  void setRouter(GoRouter router) {
    _router = router;
    if (_pendingUri != null) {
      _logger.info('Processing cold-start link: $_pendingUri');
      _handleDeepLink(_pendingUri!);
      _pendingUri = null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Routing
  // ──────────────────────────────────────────────────────────────────────────

  void _handleDeepLink(Uri uri) {
    if (_router == null) {
      _pendingUri = uri;
      return;
    }

    _logger.debug('Handling deep link → scheme:${uri.scheme} '
        'host:${uri.host} path:${uri.path}');

    try {
      // ── https://webuddhist.com/open ──────────────────────────────────────
      // Shared from the home screen share button.
      if (_isOpenLink(uri)) {
        _logger.info('Deep link → /home');
        _router!.go('/home');
        return;
      }

      // ── future routes (plan invite, reader, etc.) ────────────────────────
      // Add more cases here as needed.

      // Fallback
      _logger.warning('Unhandled deep link: $uri — falling back to /home');
      _router!.go('/home');
    } catch (e) {
      _logger.error('Error handling deep link', e);
      _router?.go('/home');
    }
  }

  /// Matches both the HTTPS universal link and the custom scheme:
  ///   https://webuddhist.com/open
  ///   webuddhist://open
  bool _isOpenLink(Uri uri) {
    final isHttps =
        (uri.scheme == 'https') && (uri.host == 'webuddhist.com') && (uri.path == '/open');
    final isCustom =
        (uri.scheme == 'webuddhist') && (uri.host == 'open');
    return isHttps || isCustom;
  }
}
