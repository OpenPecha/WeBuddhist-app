import 'package:flutter_pecha/features/ai/presentation/ai_mode_screen.dart';
import 'package:flutter_pecha/features/ai/presentation/search_results_screen.dart';
import 'package:flutter_pecha/features/auth/presentation/login_page.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/plan_list_screen.dart';
import 'package:flutter_pecha/features/more/presentation/more_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/edit_routine_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/practice_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_plan_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_recitation_screen.dart';
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

        // ai mode route
        GoRoute(
          path: "/ai-mode",
          name: "ai-mode",
          builder: (context, state) => const AiModeScreen(),
          routes: [
            // route - /ai-mode/search-results
            GoRoute(
              path: "search-results",
              name: "search-results",
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final query = extra?['query'] as String? ?? '';
                return SearchResultsScreen(initialQuery: query);
              },
            ),
          ],
        ),

        // practice route
        GoRoute(
          path: "/practice",
          name: "practice",
          builder: (context, state) => const PracticeScreen(),
          routes: [
            GoRoute(
              path: "edit-routine",
              name: "edit-routine",
              builder: (context, state) => const EditRoutineScreen(),
              routes: [
                GoRoute(
                  path: "select-plan",
                  name: "select-plan",
                  builder: (context, state) => const SelectPlanScreen(),
                ),
                GoRoute(
                  path: "select-recitation",
                  name: "select-recitation",
                  builder: (context, state) => const SelectRecitationScreen(),
                ),
              ],
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
