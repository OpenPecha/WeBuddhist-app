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
    refreshListenable: GoRouterRefreshStream(ref.watch(authProvider.notifier).stream),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const SkeletonScreen(),
      ),
    ],
    redirect: (context, state) {
      final loggedIn = authState.isLoggedIn;
      final loggingIn = state.fullPath == '/login';
      if (!loggedIn && state.fullPath != '/login' && state.fullPath != '/splash') {
        return '/login';
      }
      if (loggedIn && (loggingIn || state.fullPath == '/splash')) {
        return '/home';
      }
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
