import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/onboarding/data/onboarding_repository.dart';
import 'package:go_router/go_router.dart';

/// Route guard for authentication and authorization
///
/// Handles redirects based on auth state, onboarding status, and route permissions.
class RouteGuard {
  RouteGuard._();

  static final _logger = AppLogger('RouteGuard');
  static String? _pendingRoute;

  /// Main redirect function called by GoRouter
  static Future<String?> redirect(
    BuildContext context,
    GoRouterState state,
    AuthState authState,
    OnboardingRepository onboardingRepo,
  ) async {
    final currentPath = state.fullPath ?? AppRoutes.home;

    _logger.debug(
      'Route guard: path=$currentPath, '
      'loading=${authState.isLoading}, '
      'loggedIn=${authState.isLoggedIn}, '
      'guest=${authState.isGuest}',
    );

    // Show login while auth is loading
    if (authState.isLoading) return AppRoutes.login;

    // Route based on auth state
    if (authState.isLoggedIn && !authState.isGuest) {
      return _handleAuthenticated(currentPath, onboardingRepo);
    }
    if (authState.isGuest) {
      return _handleGuest(currentPath);
    }
    return _handleUnauthenticated(currentPath);
  }

  /// Authenticated user redirect logic
  static Future<String?> _handleAuthenticated(
    String path,
    OnboardingRepository onboardingRepo,
  ) async {
    final hasOnboarded = await onboardingRepo.hasCompletedOnboarding();

    // Force onboarding if not completed
    if (!hasOnboarded && path != AppRoutes.onboarding && path != AppRoutes.login) {
      return AppRoutes.onboarding;
    }

    // Skip onboarding if already done
    if (hasOnboarded && path == AppRoutes.onboarding) {
      return AppRoutes.home;
    }

    // Redirect from login to pending route or home
    if (path == AppRoutes.login) {
      final pending = _consumePendingRoute();
      return pending ?? AppRoutes.home;
    }

    return null;
  }

  /// Guest user redirect logic
  static String? _handleGuest(String path) {
    // Guests skip onboarding and login
    if (path == AppRoutes.onboarding || path == AppRoutes.login) {
      return AppRoutes.home;
    }

    // Block protected routes for guests
    if (!AppRoutes.isGuestAccessible(path)) {
      _logger.debug('Guest blocked from protected route: $path');
      return AppRoutes.home;
    }

    return null;
  }

  /// Unauthenticated user redirect logic
  static String? _handleUnauthenticated(String path) {
    // Allow public routes
    if (AppRoutes.isPublicRoute(path)) return null;

    // Require login for all other routes
    _logger.info('Unauthenticated access to $path, redirecting to login');
    _setPendingRoute(path);
    return AppRoutes.login;
  }

  // ========== Pending Route Management ==========

  static void _setPendingRoute(String route) {
    if (route != AppRoutes.login && route != AppRoutes.onboarding) {
      _pendingRoute = route;
    }
  }

  static String? _consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  /// Clear pending route (call on logout)
  static void clearPendingRoute() => _pendingRoute = null;
}
