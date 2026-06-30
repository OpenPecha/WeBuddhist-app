import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_router.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:go_router/go_router.dart';

class AppLinksDeepLinkService {
  AppLinksDeepLinkService._();

  static final AppLinksDeepLinkService instance = AppLinksDeepLinkService._();

  final _appLinks = AppLinks();
  final _logger = AppLogger('AppLinksDeepLinkService');

  StreamSubscription<Uri>? _subscription;
  GoRouter? _router;
  Uri? _pendingUri;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _logger.info('Cold-start app link: $initial');
        _handleLink(initial);
      }

      _subscription = _appLinks.uriLinkStream.listen(
        (uri) {
          _logger.info('Warm-start app link: $uri');
          _handleLink(uri);
        },
        onError:
            (e, stackTrace) =>
                _logger.error('App link stream error', e, stackTrace),
      );

      _logger.info('App links service initialized');
    } catch (e, stackTrace) {
      _logger.error('App links init error', e, stackTrace);
    }
  }

  void setRouter(GoRouter router) {
    _router = router;
  }

  bool drainPendingLink() {
    if (_router == null) return false;

    final pending = _pendingUri;
    if (pending == null) return false;

    _pendingUri = null;
    _dispatch(pending, baseLocation: AppRoutes.home);
    return true;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }

  void _handleLink(Uri uri) {
    if (!DeepLinkRouter.isFirstPartyAppLink(uri)) {
      _logger.debug('Ignoring non-first-party app link: $uri');
      return;
    }

    if (_router == null) {
      _pendingUri = uri;
      _logger.info('Router not ready, stored app link: $uri');
      return;
    }

    _dispatch(uri);
  }

  void _dispatch(Uri uri, {String? baseLocation}) {
    final router = _router;
    if (router == null) return;

    DeepLinkRouter.route(
      uri,
      router,
      source: 'app_links',
      baseLocation: baseLocation,
    );
  }
}
