/// Centralized configuration for protected API routes that require authentication.
class ProtectedRoutes {
  /// List of all protected API paths.
  ///
  /// Paths can contain path parameters in curly braces like {planId}, {taskId}, etc.
  /// These parameters will match any value in that segment position.
  static const List<String> paths = [
    // User profile
    '/api/v1/users/info',
    '/api/v1/users/upload',

    // User progress
    '/api/v1/users/me',
    '/api/v1/users/me/plans',
    '/api/v1/users/me/plans/{planId}',
    '/api/v1/users/me/tasks',
    '/api/v1/users/me/tasks/{taskId}/complete',
    '/api/v1/users/me/sub-tasks',
    '/api/v1/users/me/sub-tasks/{subTaskId}/complete',
    '/api/v1/users/me/task/{taskId}',
    '/api/v1/users/me/plan/{planId}/days/{dayNumber}',

    // Recitations
    '/api/v1/users/me/recitations',

    // AI chat
    '/chats',
    '/threads',
    '/threads/{threadId}',
  ];

  /// Check if a given path is protected (requires authentication).
  ///
  /// Returns true if the path matches any protected route pattern.
  static bool isProtected(String path) {
    return paths.any((route) => _matchesPathPattern(path, route));
  }

  /// Matches a path against a pattern that may contain path parameters like {planId}.
  ///
  /// Examples:
  /// - `_matchesPathPattern('/api/v1/users/me', '/api/v1/users/me')` → true
  /// - `_matchesPathPattern('/api/v1/users/me/plans/123', '/api/v1/users/me/plans/{planId}')` → true
  /// - `_matchesPathPattern('/api/v1/users/me/plans/123/tasks', '/api/v1/users/me/plans/{planId}')` → false
  static bool _matchesPathPattern(String path, String pattern) {
    // If no parameters in pattern, do simple prefix match
    if (!pattern.contains('{')) {
      return path.startsWith(pattern);
    }

    // Split both path and pattern into segments
    final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();
    final patternSegments = pattern.split('/').where((s) => s.isNotEmpty).toList();

    // Must have same number of segments
    if (pathSegments.length != patternSegments.length) {
      return false;
    }

    // Compare each segment
    for (var i = 0; i < pathSegments.length; i++) {
      final pathSegment = pathSegments[i];
      final patternSegment = patternSegments[i];

      // If pattern segment is a parameter (e.g., {planId}), it matches any value
      if (patternSegment.startsWith('{') && patternSegment.endsWith('}')) {
        continue;
      }

      // Otherwise, segments must match exactly
      if (pathSegment != patternSegment) {
        return false;
      }
    }

    return true;
  }
}
