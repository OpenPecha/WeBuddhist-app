import 'package:flutter_pecha/core/config/router/app_routes.dart';

/// Route configuration constants and utilities for the application
///
/// @deprecated Use AppRoutes and RouteGuard instead.
@Deprecated('Use AppRoutes and RouteGuard instead')
class RouteConfig {
  RouteConfig._();

  // Route paths - delegated to AppRoutes
  static const String onboarding = AppRoutes.onboarding;
  static const String login = AppRoutes.login;
  static const String home = AppRoutes.home;
  static const String profile = AppRoutes.profile;
  static const String creatorInfo = AppRoutes.creatorInfo;
  static const String plans = '/plans';
  static const String texts = AppRoutes.texts;

  // Public routes that don't require authentication
  static final Set<String> publicRoutes = AppRoutes.publicRoutes;

  @Deprecated('Use AppRoutes.requiresAuth() instead')
  static bool isProtectedRoute(String path) => AppRoutes.requiresAuth(path);

  @Deprecated('Use AppRoutes.isPublicRoute() instead')
  static bool isPublicRoute(String path) => AppRoutes.isPublicRoute(path);
}
