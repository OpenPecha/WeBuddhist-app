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
      return _DeepLinkDestination(
        _routeForWebuddhistHost(uri.host.toLowerCase()),
      );
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
        segments[1] == 'series') {
      final seriesId = segments[2];
      return _DeepLinkDestination(
        '/home/series/${Uri.encodeComponent(seriesId)}',
        opensOnTop: true,
      );
    }

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

    return const _DeepLinkDestination(AppRoutes.home);
  }

  static String _routeForWebuddhistHost(String host) {
    switch (host) {
      case 'open':
      case 'home':
        return AppRoutes.home;
      case 'practice':
        return AppRoutes.practice;
      case 'texts':
        return AppRoutes.texts;
      case 'more':
        return AppRoutes.more;
      case 'profile':
        return AppRoutes.profile;
      case 'notifications':
        return AppRoutes.notifications;
      default:
        _logger.warning('Unknown webuddhist deep link host: $host');
        return AppRoutes.home;
    }
  }
}

class _DeepLinkDestination {
  final String location;
  final Object? extra;
  final bool opensOnTop;

  const _DeepLinkDestination(
    this.location, {
    this.extra,
    this.opensOnTop = false,
  });
}
