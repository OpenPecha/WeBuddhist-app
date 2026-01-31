import 'package:flutter_pecha/features/auth/presentation/login_page.dart';
import 'package:flutter_pecha/features/home/presentation/home_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/more/presentation/more_screen.dart';
import 'package:flutter_pecha/features/plans/presentation/screens/plans_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/screens/collections/collections_screen.dart';
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
          // routes: [
          //   GoRoute(path: "practice-plans", name: "practice-plans", builder: (context, state) => const PracticePlansScree(),
          //   routes: [
          //     GoRoute(path: "plan-details", name: "plan-details", builder: (context, state) => PlanDetails(),
          //     ),
          //   ],
          // ),
        ),

        // pratice route
        GoRoute(
          path: "/pratice",
          name: "pratice",
          // builder: (context, state) => const PraticeScreen(),
          builder: (context, state) => const PlansScreen(),
        ),

        // // texts route
        GoRoute(
          path: "/texts",
          name: "texts",
          // builder: (context, state) => const TextsScreen(),
          builder: (context, state) => const CollectionsScreen(),
        ),

        // // settings route
        GoRoute(
          path: "settings",
          name: "settings",
          builder: (context, state) => const MoreScreen(),
        ),
      ],
    );
  }
}
