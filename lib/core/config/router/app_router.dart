import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/config/router/route_guard.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/presentation/ai_mode_screen.dart';
import 'package:flutter_pecha/features/ai/presentation/search_results_screen.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/login_page.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/plan_list_screen.dart';
import 'package:flutter_pecha/features/onboarding/data/providers/onboarding_datasource_providers.dart';
import 'package:flutter_pecha/features/onboarding/presentation/onboarding_wrapper.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_pecha/features/plans/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/plan_details.dart';
import 'package:flutter_pecha/features/plans/presentation/plan_info.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_preview/plan_preview_details.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/edit_routine_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/practice_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_plan_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_recitation_screen.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/reader_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/screens/chapters/chapters_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _logger = AppLogger('AppRouter');

/// Provider for the application router with authentication and route protection
///
/// This provider creates a GoRouter instance that:
/// - Protects routes based on authentication state
/// - Handles guest mode access restrictions
/// - Manages onboarding flow
/// - Preserves deep links for post-login redirection
/// - Automatically refreshes when auth state changes
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final onboardingRepo = ref.watch(onboardingRepositoryProvider);

  _logger.debug('Creating router with auth state: ${authState.isLoggedIn}');

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,

    // Refresh router when auth state changes
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authProvider.notifier).stream,
    ),

    // Route guard for authentication and authorization
    redirect: (context, state) async {
      return await RouteGuard.redirect(
        context,
        state,
        authState,
        onboardingRepo,
      );
    },

    routes: [
      GoRoute(
        path: "/login",
        name: "login",
        builder: (context, state) => const LoginPage(),
      ),
      // onboarding route
      GoRoute(
        path: "/onboarding",
        name: "onboarding",
        builder: (context, state) => const OnboardingWrapper(),
      ),

      // home route
      GoRoute(
        path: "/home",
        name: "home",
        builder: (context, state) => const MainNavigationScreen(),
        routes: [
          GoRoute(
            path: "plans/:tag", // route - /home/plans/:tag
            name: "home-plans",
            builder: (context, state) {
              final tag = state.pathParameters['tag'] ?? '';
              return PlanListScreen(tag: tag);
            },
            routes: [
              GoRoute(
                path: "preview", // route - /home/plans/:tag/preview
                name: "home-plan-preview",
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final plan = extra?['plan'] as PlansModel?;
                  if (plan == null) {
                    throw Exception('Missing required parameters');
                  }
                  return PlanPreviewDetails(plan: plan);
                },
              ),
            ],
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
            path: "search-results", // route - /ai-mode/search-results
            name: "search-results",
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final query = extra?['query'] as String? ?? '';
              return SearchResultsScreen(initialQuery: query);
            },
            routes: [
              GoRoute(
                path: "text-chapters", // /ai-mode/search-results/text-chapters
                name: "text-chapters",
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final textId = extra?['textId'] as String? ?? '';
                  final segmentId = extra?['segmentId'] as String?;
                  return ChaptersScreen(textId: textId, segmentId: segmentId);
                },
              ),
            ],
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
            path: "edit-routine", // route - /practice/edit-routine
            name: "edit-routine",
            builder: (context, state) => const EditRoutineScreen(),
            routes: [
              GoRoute(
                path:
                    "select-plan", // route - /practice/edit-routine/select-plan
                name: "select-plan",
                builder: (context, state) => const SelectPlanScreen(),
              ),
              GoRoute(
                path:
                    "select-recitation", // route - /practice/edit-routine/select-recitation
                name: "select-recitation",
                builder: (context, state) => const SelectRecitationScreen(),
              ),
            ],
          ),
          // route - /practice/texts/:textId
          GoRoute(
            path: "texts/:textId",
            name: "practice-text",
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final textId = state.pathParameters['textId'] ?? '';
              final segmentId = extra?["segmentId"] as String?;
              return ChaptersScreen(textId: textId, segmentId: segmentId);
            },
          ),
          // route - /practice/plans/preview (preview plan before enrollment)
          GoRoute(
            path: "plans/preview",
            name: "practice-plan-preview",
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final plan = extra?['plan'] as PlansModel?;
              if (plan == null) {
                throw Exception('Missing required parameters');
              }
              return PlanPreviewDetails(plan: plan);
            },
          ),
          // route - /practice/plans/info
          GoRoute(
            path: "plans/info",
            name: "practice-plan-info",
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final plan = extra?['plan'] as PlansModel?;
              if (plan == null) {
                throw Exception('Missing required parameters');
              }
              return PlanInfo(plan: plan);
            },
            routes: [
              // route - /practice/plans/info/details
              GoRoute(
                path: "details",
                name: "practice-plan-details",
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final plan = extra?['plan'] as UserPlansModel?;
                  final selectedDay = extra?['selectedDay'] as int?;
                  final startDate = extra?['startDate'] as DateTime?;
                  if (plan == null) {
                    throw Exception('Missing required parameters');
                  }
                  return PlanDetails(
                    plan: plan,
                    selectedDay: selectedDay ?? 0,
                    startDate: startDate ?? DateTime.now(),
                  );
                },
              ),
              // route - /practice/plans/info/author
              // GoRoute(
              //   path: "author",
              //   name: "practice-plan-author",
              //   builder: (context, state) => const AuthorDetailScreen(),
              // ),
            ],
          ),
        ],
      ),

      // reader route - new refactored text reader
      GoRoute(
        path: "/reader/:textId",
        name: "reader",
        builder: (context, state) {
          final textId = state.pathParameters['textId'] ?? '';
          final extra = state.extra;
          String? segmentId;

          // Extract navigation context if provided
          NavigationContext? navigationContext;
          if (extra is NavigationContext) {
            navigationContext = extra;
            segmentId = extra.targetSegmentId;
          } else if (extra is Map<String, dynamic>) {
            // Support passing as map for flexibility
            segmentId = extra['segmentId'] as String?;
            final sourceStr = extra['source'] as String?;
            final planTextItems = extra['planTextItems'] as List<PlanTextItem>?;
            final currentTextIndex = extra['currentTextIndex'] as int?;

            NavigationSource source = NavigationSource.normal;
            if (sourceStr == 'plan') {
              source = NavigationSource.plan;
            } else if (sourceStr == 'search') {
              source = NavigationSource.search;
            } else if (sourceStr == 'deepLink') {
              source = NavigationSource.deepLink;
            }

            navigationContext = NavigationContext(
              source: source,
              targetSegmentId: segmentId,
              planTextItems: planTextItems,
              currentTextIndex: currentTextIndex ?? 0,
            );
          }

          return ReaderScreen(
            textId: textId,
            navigationContext: navigationContext,
            segmentId: segmentId,
          );
        },
      ),
    ],

    // Error handling for invalid routes
    errorBuilder: (context, state) {
      _logger.warning('Route error: ${state.error}');
      return const MainNavigationScreen();
    },
  );
});


/// This allows the router to automatically refresh when auth state changes,
/// triggering redirect logic to re-evaluate route access permissions.
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
