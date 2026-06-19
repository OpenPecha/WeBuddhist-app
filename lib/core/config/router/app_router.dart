import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/config/router/page_transitions.dart';
import 'package:flutter_pecha/core/config/router/route_guard.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/presentation/screens/ai_mode_screen.dart';
import 'package:flutter_pecha/features/ai/presentation/screens/search_results_screen.dart';
import 'package:flutter_pecha/core/config/router/pending_route_provider.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/screens/login_page.dart';
import 'package:flutter_pecha/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_pecha/features/calendar/presentation/screens/tibetan_calendar_screen.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_profile_screen.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/plan_list_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/series_detail_screen.dart';
import 'package:flutter_pecha/features/home/presentation/screens/series_info_screen.dart';
import 'package:flutter_pecha/features/more/presentation/about_screen.dart';
import 'package:flutter_pecha/features/more/presentation/edit_profile_screen.dart';
import 'package:flutter_pecha/features/more/presentation/more_screen.dart';
import 'package:flutter_pecha/features/more/presentation/legal.dart';
import 'package:flutter_pecha/features/more/presentation/privacy_policy_screen.dart';
import 'package:flutter_pecha/features/more/presentation/delete_account_screen.dart';
import 'package:flutter_pecha/features/more/presentation/terms_of_service_screen.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/onboarding_datasource_providers.dart';
import 'package:flutter_pecha/features/onboarding/presentation/screens/onboarding_wrapper.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/screens/plan_text_screen.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/plan_details.dart';
import 'package:flutter_pecha/features/plans/presentation/plan_info.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_preview/plan_preview_details.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/edit_routine_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/practice_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_plan_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_recitation_screen.dart';
import 'package:flutter_pecha/features/mala/presentation/screens/mala_screen.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/screens/reader_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/screens/chapters/chapters_screen.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_image/choose_image.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_image/create_image.dart';
import 'package:flutter_pecha/features/texts/presentation/version_selection/language_selection.dart';
import 'package:flutter_pecha/features/texts/presentation/version_selection/version_selection_screen.dart';
import 'package:flutter_pecha/features/timer/presentation/screens/active_timer_screen.dart';
import 'package:flutter_pecha/features/timer/presentation/screens/preset_timers_screen.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _logger = AppLogger('AppRouter');

/// Root navigator key for the GoRouter instance.
///
/// Exposed so widgets above the navigator tree (e.g. ForceUpdateGate)
/// can call showDialog on a context that is actually inside the navigator.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Shell navigator key for routes that share the persistent bottom nav bar.
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Provider for the application router with authentication and route protection
///
/// This provider creates a GoRouter instance that:
/// - Protects routes based on authentication state
/// - Handles guest mode access restrictions
/// - Manages onboarding flow
/// - Preserves deep links for post-login redirection
/// - Automatically refreshes when auth state changes
final appRouterProvider = Provider<GoRouter>((ref) {
  // Use ref.read so the router is created once and never recreated on auth
  // state changes.
  final onboardingRepo = ref.read(onboardingRepositoryProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    observers: [ref.read(analyticsServiceProvider).routeObserver],

    // Re-evaluate redirect whenever auth state changes.
    refreshListenable: GoRouterRefreshStream(
      ref.read(authProvider.notifier).stream,
    ),

    // Route guard for authentication and authorization.
    // Always reads the latest auth state — do NOT capture it in the closure.
    redirect: (context, state) async {
      return await RouteGuard.redirect(
        context,
        state,
        ref.read(authProvider),
        onboardingRepo,
        getPendingRoute: () => ref.read(pendingRouteProvider),
        setPendingRoute:
            (route) => ref.read(pendingRouteProvider.notifier).state = route,
      );
    },

    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Universal / App Link entry point shared from the home screen.
      // Handled by DeepLinkService for cold-start; this route is the
      // warm-start fallback in case go_router intercepts the URI directly.
      GoRoute(
        path: '/open',
        name: 'open',
        redirect: (_, __) => AppRoutes.home,
      ),
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

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return HomeShellScaffold(child: child);
        },
        routes: [
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
                routes: [
                  GoRoute(
                    parentNavigatorKey: rootNavigatorKey,
                    path: "preview",
                    name: "home-plan-preview",
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final plan = extra?['plan'] as Plan?;
                      if (plan == null) {
                        throw Exception('Missing required parameters');
                      }
                      return PlanPreviewDetails(plan: plan);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: "series/:id",
                name: "home-series-detail",
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  final extra = state.extra as Map<String, dynamic>?;
                  final series = extra?['series'] as Series?;
                  return SeriesDetailScreen(seriesId: id, series: series);
                },
                routes: [
                  GoRoute(
                    path: "info",
                    name: "home-series-info",
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final series = extra?['series'] as Series;
                      return SeriesInfoScreen(series: series);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: "group/:groupId",
                name: "home-group-profile",
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId'] ?? '';
                  return GroupProfileScreen(groupId: groupId);
                },
              ),
              GoRoute(
                path: "timers",
                name: "home-timers",
                builder: (context, state) => const PresetTimersScreen(),
                routes: [
                  GoRoute(
                    path: "active",
                    name: "home-timer-active",
                    builder: (context, state) {
                      final timer = state.extra as PresetTimer?;
                      if (timer == null) {
                        throw Exception('Missing preset timer');
                      }
                      return ActiveTimerScreen(presetTimer: timer);
                    },
                  ),
                ],
              ),
              // settings route
              GoRoute(
                path: "settings",
                name: "home-settings",
                builder: (context, state) => const MoreScreen(),
              ),
              // calendar route
              GoRoute(
                path: "calendar",
                name: "home-calendar",
                builder: (context, state) => const TibetanCalendarScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: "notifications",
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: "profile",
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.about,
            name: "about",
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: AppRoutes.legal,
            name: "legal",
            builder: (context, state) => const LegalScreen(),
          ),
          GoRoute(
            path: AppRoutes.termsOfService,
            name: "terms-of-service",
            builder: (context, state) => const TermsOfServiceScreen(),
          ),
          GoRoute(
            path: AppRoutes.privacyPolicy,
            name: "privacy-policy",
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),
          GoRoute(
            path: AppRoutes.deleteAccount,
            name: "delete-account",
            builder: (context, state) => const DeleteAccountScreen(),
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

      // mala route (login-gated digital prayer beads)
      GoRoute(
        path: AppRoutes.mala,
        name: "mala",
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MalaScreen(
            initialPresetId: extra?['presetId'] as String?,
          );
        },
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
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final plan = extra?['initialPlan'] as Plan?;
              final enrollSeriesId = extra?['enrollSeriesId'] as String?;
              return EditRoutineScreen(
                initialPlan: plan,
                enrollSeriesId: enrollSeriesId,
              );
            },
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
          // route - /practice/details
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
                selectedDay: selectedDay ?? 1,
                startDate: startDate ?? DateTime.now(),
              );
            },
          ),
          // route - /practice/plans/preview
          GoRoute(
            path: "plans/preview",
            name: "practice-plan-preview",
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final plan = extra?['plan'] as Plan?;
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
              final plan = extra?['plan'] as Plan?;
              if (plan == null) {
                throw Exception('Missing required parameters');
              }
              return PlanInfo(plan: plan);
            },
            routes: [
              // route - /practice/plans/info/details
              GoRoute(
                path: "details",
                name: "practice-plan-info-details",
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
                    selectedDay: selectedDay ?? 1,
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

      // route - /choose-image (choose image)
      GoRoute(
        path: "/choose-image",
        name: "choose-image",
        builder: (context, state) {
          final extra = state.extra as String?;
          if (extra == null) {
            throw Exception('Missing required parameters');
          }
          return ChooseImage(text: extra);
        },
      ),
      // route - /create-image (create image)
      GoRoute(
        path: "/create-image",
        name: "create-image",
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CreateImage(
            text: extra?['text'] as String,
            imagePath: extra?['imagePath'] as String,
          );
        },
      ),

      // plan text route - inline TEXT subtasks (sibling to /reader)
      GoRoute(
        path: "/plan-text/:subtaskId",
        name: "plan-text",
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is! NavigationContext) {
            _logger.warning(
              'plan-text route called without NavigationContext extra',
            );
            return const MaterialPage(child: MainNavigationScreen());
          }

          return CustomTransitionPage(
            key: state.pageKey,
            child: PlanTextScreen(navigationContext: extra),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return buildPlanNavigationTransition(
                context,
                animation,
                secondaryAnimation,
                child,
                extra.navigationDirection,
              );
            },
          );
        },
      ),

      // reader route - new refactored text reader
      GoRoute(
        path: "/reader/:textId",
        name: "reader",
        pageBuilder: (context, state) {
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

          final screen = ReaderScreen(
            textId: textId,
            navigationContext: navigationContext,
            segmentId: segmentId,
          );

          // Use directional transition for plan navigation
          if (navigationContext != null &&
              navigationContext.source == NavigationSource.plan) {
            final direction = navigationContext.navigationDirection;
            return CustomTransitionPage(
              key: state.pageKey,
              child: screen,
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return buildPlanNavigationTransition(
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                  direction,
                );
              },
            );
          }

          // Default MaterialPage for non-plan navigation
          return MaterialPage(key: state.pageKey, child: screen);
        },
        routes: [
          // route - /reader/:textId/versions (version selection)
          GoRoute(
            path: "versions",
            name: "reader-versions",
            builder: (context, state) {
              final textId = state.pathParameters['textId'] ?? '';
              return VersionSelectionScreen(textId: textId);
            },
            routes: [
              // route - /reader/:textId/versions/language (language selection)
              GoRoute(
                path: "language",
                name: "reader-versions-language",
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final uniqueLanguages =
                      extra?['uniqueLanguages'] as List<String>?;
                  return LanguageSelectionScreen(
                    uniqueLanguages: uniqueLanguages ?? [],
                  );
                },
              ),
            ],
          ),
        ],
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
