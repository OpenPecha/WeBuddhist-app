import 'package:flutter_pecha/features/auth/presentation/login_page.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/plan_list_screen.dart';
import 'package:flutter_pecha/features/more/presentation/more_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  late final GoRouter router;

  AppRouter() {
    router = GoRouter(
      initialLocation: "/home",
      routes: [
        GoRoute(
          path: "/login",
          name: "login",
          builder: (context, state) => const LoginPage(),
        ),

        // home route
        GoRoute(
          path: "/home",
          name: "home",
          builder: (context, state) => const MainNavigationScreen(),
          routes: [
            GoRoute(
              path: "plans/:tag",
              name: "home-plans",
              builder: (context, state) {
                final tag = state.pathParameters['tag'] ?? '';
                return PlanListScreen(tag: tag);
              },
            ),
          ],
        ),

        GoRoute(
          path: "settings",
          name: "settings",
          builder: (context, state) => const MoreScreen(),
        ),
      ],
    );
  }
}
