import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:go_router/go_router.dart';

/// Route guard for authentication and authorization
///
/// Handles redirects based on auth state, onboarding status, and route permissions.
///
/// The onboarding completion flag is read directly from [AuthState.hasCompletedOnboarding],
/// which is prefetched once during login/auth-restore in [AuthNotifier]. This makes
/// every redirect synchronous — no network call on each navigation.
class RouteGuard {
  RouteGuard._();

  static final _logger = AppLogger('RouteGuard');

  /// Main redirect function called by GoRouter.
  ///
  /// [getPendingRoute] — returns the currently saved pending route.
  /// [setPendingRoute] — saves or clears the pending route (pass null to clear).
  static String? redirect(
    BuildContext context,
    GoRouterState state,
    AuthState authState, {
    required String? Function() getPendingRoute,
    required void Function(String?) setPendingRoute,
  }) {
    final currentPath = state.fullPath ?? AppRoutes.home;

    _logger.debug(
      'Route guard: path=$currentPath, '
      'loading=${authState.isLoading}, '
      'loggedIn=${authState.isLoggedIn}, '
      'guest=${authState.isGuest}',
    );

    // Show splash while auth is loading.
    if (authState.isLoading) return AppRoutes.splash;

    // Route based on auth state
    if (authState.isLoggedIn && !authState.isGuest) {
      return _handleAuthenticated(
        currentPath,
        authState.hasCompletedOnboarding,
        getPendingRoute,
        setPendingRoute,
      );
    }
    if (authState.isGuest) {
      return _handleGuest(currentPath);
    }
    return _handleUnauthenticated(currentPath, setPendingRoute);
  }

  /// Authenticated user redirect logic
  static String? _handleAuthenticated(
    String path,
    bool? hasOnboarded,
    String? Function() getPendingRoute,
    void Function(String?) setPendingRoute,
  ) {
    // Force onboarding only when status was fetched and is not completed.
    // null means the fetch is still pending (e.g. offline launch) — skip
    // enforcement rather than blocking the user.
    if (hasOnboarded == false &&
        path != AppRoutes.onboarding &&
        path != AppRoutes.login) {
      return AppRoutes.onboarding;
    }

    // Completed users, and cases where status is unknown, go to home — not onboarding.
    if (hasOnboarded != false && path == AppRoutes.onboarding) {
      return AppRoutes.home;
    }

    // Redirect from login or splash to pending route or home
    if (path == AppRoutes.login || path == AppRoutes.splash) {
      final pending = getPendingRoute();
      setPendingRoute(null);
      return pending ?? AppRoutes.home;
    }

    return null;
  }

  /// Guest user redirect logic
  static String? _handleGuest(String path) {
    // Guests skip onboarding, login, and splash
    if (path == AppRoutes.onboarding ||
        path == AppRoutes.login ||
        path == AppRoutes.splash) {
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
  static String? _handleUnauthenticated(
    String path,
    void Function(String?) setPendingRoute,
  ) {
    // Allow public routes; once loading is done, forward splash → login
    if (AppRoutes.isPublicRoute(path)) {
      if (path == AppRoutes.splash) return AppRoutes.login;
      return null;
    }

    // Require login for all other routes
    _logger.info('Unauthenticated access to $path, redirecting to login');
    if (path != AppRoutes.login &&
        path != AppRoutes.onboarding &&
        path != AppRoutes.splash) {
      setPendingRoute(path);
    }
    return AppRoutes.login;
  }
}
