import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

/// Simple in-memory cache for GET requests.
///
/// This interceptor caches GET requests in memory for a short duration
/// to avoid redundant network calls. For more advanced caching,
/// consider using dio_cache_interceptor.
class CacheInterceptor extends Interceptor {
  CacheInterceptor(this._logger);

  final AppLogger _logger;
  final Map<String, _CacheEntry> _cache = {};

  /// Default TTL for cache entries (5 minutes)
  static const defaultTTL = Duration(minutes: 5);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Only cache GET requests
    if (options.method.toUpperCase() == 'GET') {
      final cacheKey = _generateCacheKey(options);
      final cached = _cache[cacheKey];

      if (cached != null && !cached.isExpired) {
        _logger.info('📦 Cache HIT: $cacheKey');
        // Return cached data as a successful response
        handler.resolve(
          Response(
            requestOptions: options,
            data: cached.data,
            statusCode: 200,
            extra: {'cached': true},
          ),
        );
        return;
      } else if (cached != null && cached.isExpired) {
        // Remove expired entry
        _cache.remove(cacheKey);
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // Cache successful GET responses
    final request = response.requestOptions;
    if (request.method.toUpperCase() == 'GET' &&
        response.statusCode == 200 &&
        !response.extra.containsKey('cached')) {
      final cacheKey = _generateCacheKey(request);
      final ttl = request.extra['cache_ttl'] as Duration? ?? defaultTTL;

      _cache[cacheKey] = _CacheEntry(
        data: response.data,
        expiry: DateTime.now().add(ttl),
      );

      _logger.debug('Cached response for: $cacheKey (TTL: $ttl)');
    }

    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // Don't cache errors
    handler.next(err);
  }

  /// Generate a unique cache key for the request
  String _generateCacheKey(RequestOptions options) {
    final path = options.path;
    final queryParams = options.queryParameters;
    if (queryParams.isEmpty) {
      return path;
    }
    // Sort query params for consistent keys
    final sortedParams = queryParams.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final queryString = sortedParams
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '$path?$queryString';
  }

  /// Clear all cached entries
  void clear() {
    _cache.clear();
    _logger.info('Cache cleared');
  }

  /// Remove a specific cache entry
  void invalidate(String path) {
    _cache.removeWhere((key, _) => key.startsWith(path));
    _logger.info('Cache invalidated for: $path');
  }
}

class _CacheEntry {
  _CacheEntry({
    required this.data,
    required this.expiry,
  });

  final dynamic data;
  final DateTime expiry;

  bool get isExpired => DateTime.now().isAfter(expiry);
}
