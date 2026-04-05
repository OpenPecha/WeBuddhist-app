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
    final request = response.requestOptions;
    final method = request.method.toUpperCase();
    final statusCode = response.statusCode ?? 0;

    // Auto-invalidate related GET cache when mutations succeed
    if (_isMutationMethod(method) && _isSuccessStatus(statusCode)) {
      final relatedPaths = _extractRelatedPaths(request.path);
      for (final path in relatedPaths) {
        invalidate(path);
      }
      _logger.info('🗑️ Auto-invalidated cache for mutation on: $relatedPaths');
    }

    // Cache successful GET responses
    if (method == 'GET' &&
        statusCode == 200 &&
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

  /// Check if HTTP method is a mutation (modifies data)
  bool _isMutationMethod(String method) {
    return method == 'POST' ||
        method == 'PUT' ||
        method == 'PATCH' ||
        method == 'DELETE';
  }

  /// Check if status code indicates success
  bool _isSuccessStatus(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  /// Extract base paths for cache invalidation.
  /// Returns list of paths to invalidate for comprehensive cache clearing.
  List<String> _extractRelatedPaths(String path) {
    final paths = <String>[];
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    
    // Remove trailing action segments like "complete"
    if (segments.isNotEmpty && _isActionSegment(segments.last)) {
      segments.removeLast();
    }
    
    // If last segment looks like an ID, remove it for the base path
    if (segments.isNotEmpty && _looksLikeId(segments.last)) {
      segments.removeLast();
    }
    
    paths.add('/${segments.join('/')}');
    
    // For task/subtask mutations, also invalidate plan-related caches
    // This handles: /users/me/tasks/..., /users/me/task/..., /users/me/sub-tasks/...
    if (path.contains('/task') || path.contains('/sub-task')) {
      paths.add('/users/me/plan');
      paths.add('/users/me/plans');
    }
    
    return paths;
  }

  /// Check if a segment is an action (not data to be cached)
  bool _isActionSegment(String value) {
    const actions = ['complete', 'incomplete', 'toggle', 'delete', 'archive'];
    return actions.contains(value.toLowerCase());
  }

  /// Check if a string looks like an ID (UUID or numeric)
  bool _looksLikeId(String value) {
    // Check for UUID format
    if (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(value)) return true;
    // Check for numeric ID
    if (RegExp(r'^\d+$').hasMatch(value)) return true;
    return false;
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
