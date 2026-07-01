import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:go_router/go_router.dart';

class DeepLinkRouter {
  DeepLinkRouter._();

  static final _logger = AppLogger('DeepLinkRouter');

  static bool route(
    Uri uri,
    GoRouter router, {
    required String source,
    String? baseLocation,
    void Function(int tabIndex)? tabSetter,
  }) {
    try {
      final destination = _resolveRoute(uri);
      if (destination == null) {
        _logger.warning('Unhandled deep link from $source: $uri');
        return false;
      }

      _logger.info('Deep link from $source -> ${destination.location} ($uri)');
      if (destination.opensOnTop && baseLocation != null) {
        router.go(baseLocation);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          router.push(destination.location, extra: destination.extra);
        });
      } else if (destination.opensOnTop) {
        router.push(destination.location, extra: destination.extra);
      } else {
        router.go(destination.location, extra: destination.extra);
      }

      final tabIndex = destination.tabIndex;
      if (tabIndex != null && tabSetter != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          tabSetter(tabIndex);
        });
      }

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Error routing deep link from $source: $uri',
        e,
        stackTrace,
      );
      return false;
    }
  }

  static bool isFirstPartyAppLink(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'https' || scheme == 'http') &&
        uri.host.toLowerCase() == 'webuddhist.com' &&
        (uri.path == '/open' || uri.path.startsWith('/open/'));
  }

  static bool isAirbridgeLink(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();

    return scheme == 'webuddhist' ||
        host == 'join.webuddhist.com' ||
        host.endsWith('.airbridge.io') ||
        host.endsWith('.abr.ge');
  }

  static _DeepLinkDestination? _resolveRoute(Uri uri) {
    if (isFirstPartyAppLink(uri)) {
      return _resolveFirstPartyAppLink(uri);
    }

    if (uri.scheme.toLowerCase() == 'webuddhist') {
      return _resolveWebuddhistSchemeLink(uri.host.toLowerCase());
    }

    if (isAirbridgeLink(uri)) {
      return const _DeepLinkDestination(AppRoutes.home);
    }

    return null;
  }

  static _DeepLinkDestination _resolveFirstPartyAppLink(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length >= 3 &&
        segments[0] == 'open' &&
        segments[1] == 'reader') {
      final textId = segments[2];
      final segmentId =
          uri.queryParameters['segment'] ?? uri.queryParameters['segmentId'];

      return _DeepLinkDestination(
        '/reader/${Uri.encodeComponent(textId)}',
        extra: NavigationContext(
          source: NavigationSource.deepLink,
          targetSegmentId: segmentId,
        ),
        opensOnTop: true,
      );
    }

    if (segments.length >= 2 &&
        segments[0] == 'open' &&
        segments[1] == 'reader') {
      final textId = uri.queryParameters['textId'];
      final segmentId =
          uri.queryParameters['segment'] ?? uri.queryParameters['segmentId'];

      if (textId != null && textId.isNotEmpty) {
        return _DeepLinkDestination(
          '/reader/${Uri.encodeComponent(textId)}',
          extra: NavigationContext(
            source: NavigationSource.deepLink,
            targetSegmentId: segmentId,
          ),
          opensOnTop: true,
        );
      }
    }

    if (segments.length >= 2 &&
        segments[0] == 'open' &&
        segments[1] == 'more') {
      return const _DeepLinkDestination(AppRoutes.home, tabIndex: _meTabIndex);
    }

    if (segments.length >= 3 &&
        segments[0] == 'open' &&
        segments[1] == 'mala') {
      final presetId = segments[2];
      return _DeepLinkDestination(
        AppRoutes.mala,
        extra: {'presetId': presetId},
        opensOnTop: true,
      );
    }

    if (segments.length >= 3 &&
        segments[0] == 'open' &&
        segments[1] == 'timer') {
      return const _DeepLinkDestination(
        '/home/timers',
        opensOnTop: true,
      );
    }

    return const _DeepLinkDestination(AppRoutes.home);
  }

  static _DeepLinkDestination _resolveWebuddhistSchemeLink(String host) {
    switch (host) {
      case 'open':
      case 'home':
        return const _DeepLinkDestination(AppRoutes.home);
      case 'practice':
        return const _DeepLinkDestination(AppRoutes.practice);
      case 'texts':
        return const _DeepLinkDestination(AppRoutes.texts);
      case 'more':
        return const _DeepLinkDestination(AppRoutes.home, tabIndex: _meTabIndex);
      case 'profile':
        return const _DeepLinkDestination(AppRoutes.profile);
      case 'notifications':
        return const _DeepLinkDestination(AppRoutes.notifications);
      default:
        _logger.warning('Unknown webuddhist deep link host: $host');
        return const _DeepLinkDestination(AppRoutes.home);
    }
  }
}

/// Bottom nav tab index for the Me screen (matches MainTab.me.index == 3).
const int _meTabIndex = 3;

class _DeepLinkDestination {
  final String location;
  final Object? extra;
  final bool opensOnTop;

  /// When non-null, the deep-link handler should switch the bottom nav bar to
  /// this tab index after navigating. Used for tab-based screens that share
  /// the `/home` route (e.g. the Me tab).
  final int? tabIndex;

  const _DeepLinkDestination(
    this.location, {
    this.extra,
    this.opensOnTop = false,
    this.tabIndex,
  });
}
