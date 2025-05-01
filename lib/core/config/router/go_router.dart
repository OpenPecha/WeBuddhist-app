import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/features/auth/presentation/login_page.dart';
import 'package:flutter_pecha/features/app/presentation/skeleton_screen.dart';
import 'package:flutter_pecha/features/splash/presentation/splash_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authProvider.notifier).stream,
    ),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const SkeletonScreen(),
      ),
    ],
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.isLoggedIn;
      final onSplash = state.fullPath == '/splash';
      final onLogin = state.fullPath == '/login';

      // // 1. If loading, stay on splash screen
      if (isLoading) {
        return '/login';
      }

      // 2. If not loading and on splash, go to login or home
      if (!isLoading && onSplash) {
        return isLoggedIn ? '/home' : '/login';
      }

      // 3. If not logged in and not on login/splash, go to login
      if (!isLoggedIn && !onLogin && !onSplash) {
        return '/login';
      }

      // 4. If logged in and on login, go to home
      if (isLoggedIn && onLogin) {
        return '/home';
      }

      // 5. No redirect needed
      return null;
    },
  );
});

/// Utility for GoRouter to listen to Riverpod StateNotifier
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListener = () => notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListener());
  }
  late final void Function() notifyListener;
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
