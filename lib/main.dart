import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/analytics/posthog_analytics_service.dart';
import 'package:flutter_pecha/core/cache/cache_service.dart';
import 'package:flutter_pecha/core/config/app_feature_flags.dart';
import 'package:flutter_pecha/core/config/router/app_router.dart';
import 'package:flutter_pecha/core/deep_linking/app_links_deep_link_service.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/l10n/l10n.dart';
import 'package:flutter_pecha/core/services/airbridge_deep_link_service.dart';
import 'package:flutter_pecha/core/services/service_providers.dart';
import 'package:flutter_pecha/core/storage/plan_metadata_store.dart';
import 'package:flutter_pecha/core/storage/special_plan_started_at_store.dart';
import 'package:flutter_pecha/core/theme/theme_notifier.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_bootstrap.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/home/data/datasource/home_local_datasource.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/more/data/datasource/user_stats_local_datasource.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_local_storage.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:fquery/fquery.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/material_localizations_bo.dart';
import 'core/localization/cupertino_localizations_bo.dart';
import 'package:flutter_pecha/core/services/upgrade/force_update_gate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:airbridge_flutter_sdk/airbridge_flutter_sdk.dart';

final _logger = AppLogger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await PostHogAnalyticsService.create().initialize();
    _logger.info('Analytics initialized');
  } catch (e) {
    _logger.warning('Error initializing analytics: $e');
  }

  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Setup environment-aware logging
  AppLogger.init();

  // Enable Google Fonts runtime fetching for automatic font management
  // Fonts are downloaded once and cached locally for offline use
  GoogleFonts.config.allowRuntimeFetching = true;

  // Note: .env files are loaded by flavor-specific entry points (main_dev.dart, main_staging.dart, main_prod.dart)

  // Initialize cache service for offline-first data
  try {
    await CacheService.instance.initialize();
    _logger.info('Cache service initialized');
  } catch (e) {
    _logger.warning('Error initializing cache service: $e');
    // Continue app initialization even if cache fails
  }

  // Initialize connectivity service for offline detection
  try {
    await ConnectivityService.instance.initialize();
    _logger.info('Connectivity service initialized');
  } catch (e) {
    _logger.warning('Error initializing connectivity service: $e');
    // Continue app initialization even if connectivity check fails
  }

  // Cancel any previously scheduled notifications in Coming Soon mode
  if (AppFeatureFlags.kComingSoonMode) {
    try {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();
      await notificationsPlugin.cancelAll();
      _logger.info(
        'Cancelled all scheduled notifications for Coming Soon mode',
      );
    } catch (e) {
      _logger.warning('Error cancelling notifications: $e');
    }
  }

  // Initialize notification service early so scheduled notifications can fire
  // even when the app is in the background or was just launched from a tap.
  try {
    await NotificationService().initializeWithoutPermissions();
    _logger.info('Notification service initialized');
  } catch (e) {
    _logger.warning('Error initializing notification service: $e');
  }

  // Prime notification caches so schedulers can read startedAt / totalDays
  // synchronously without awaiting SharedPreferences at schedule time.
  try {
    await SpecialPlanStartedAtStore.init();
    await PlanMetadataStore.init();
  } catch (e) {
    _logger.warning('Error initializing plan metadata stores: $e');
  }

  // Initialize routine local storage (persistent user data, not cache)
  final routineStorage = RoutineLocalStorage();
  try {
    await routineStorage.initialize();
    _logger.info('Routine local storage initialized');
  } catch (e) {
    _logger.warning('Error initializing routine local storage: $e');
  }

  // Initialize mala counts local storage (per-user namespaced, not cache)
  try {
    await MalaLocalDataSource.init();
    _logger.info('Mala local storage initialized');
  } catch (e) {
    _logger.warning('Error initializing mala local storage: $e');
  }

  // Initialize Home local storage (source of truth for local-first Home).
  try {
    await HomeLocalDatasource.init();
    _logger.info('Home local storage initialized');
  } catch (e) {
    _logger.warning('Error initializing home local storage: $e');
  }

  // Initialize Me stats local storage (source of truth for local-first stats).
  try {
    await UserStatsLocalDatasource.init();
    _logger.info('Me stats local storage initialized');
  } catch (e) {
    _logger.warning('Error initializing me stats local storage: $e');
  }

  // Create provider container for routine storage
  final container = ProviderContainer(
    overrides: [routineLocalStorageProvider.overrideWithValue(routineStorage)],
  );

  // Set container reference for notification navigation
  NotificationService.setContainer(container);

  // Initialize Airbridge deep link handler
  try {
    Airbridge.setOnDeeplinkReceived((url) {
      _logger.info('Airbridge deep link received: $url');
      AirbridgeDeepLinkService.storePendingDeepLink(url);
    });
    _logger.info('Airbridge deep link handler initialized');
  } catch (e) {
    _logger.warning('Error initializing Airbridge deep link handler: $e');
  }

  try {
    await AppLinksDeepLinkService.instance.initialize();
  } catch (e) {
    _logger.warning('Error initializing app links handler: $e');
  }

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  bool _hasRegisteredDeepLinkRouters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reconcile on every foreground return, wherever the user is in the
      // app: picks up OS permission changes, timezone moves, and day
      // rollovers. The engine is idempotent and serialises concurrent
      // triggers, so overlapping with screen-level resume syncs is safe.
      ref
          .read(notificationSyncEngineProvider)
          .sync(trigger: SyncTrigger.appResume);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Get the singleton router instance - same instance is reused across rebuilds
    // final router = AppRouter().router;
    final router = ref.watch(appRouterProvider);

    // Register the router once so both deep-link sources can drain links that
    // arrived during cold start and dispatch warm links immediately afterward.
    if (!_hasRegisteredDeepLinkRouters) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AirbridgeDeepLinkService.setRouter(router);
        AppLinksDeepLinkService.instance.setRouter(router);
      });
      _hasRegisteredDeepLinkRouters = true;
    }

    // Initialize services in background via providers
    ref.watch(audioHandlerProvider);
    ref.watch(notificationServiceProvider);
    // Bootstrap listener — kept alive for the app lifetime.
    // Mirrors server-truth plan metadata into PlanMetadataStore +
    // SpecialPlanStartedAtStore, then delegates to NotificationSyncEngine
    // for full reconciliation on every userPlansFutureProvider resolution.
    ref.watch(notificationSyncBootstrapProvider);
    // Mala background sync — kept alive for the app lifetime so offline counts
    // flush on lifecycle/connectivity triggers even off the mala screen.
    ref.watch(malaSyncManagerProvider);
    // Home background sync — flushes pending local-first writes when
    // connectivity returns.
    ref.watch(homeSyncBootstrapProvider);
    NotificationService.setRouter(router);
    NotificationService().consumeLaunchNotification();

    // Add QueryClient provider wrapper
    return QueryClientProvider(
      queryClient: QueryClient(
        defaultQueryOptions: DefaultQueryOptions(
          staleDuration: const Duration(
            minutes: 5,
          ), // Data stays fresh for 5 minutes
          cacheDuration: const Duration(
            minutes: 10,
          ), // Cache persists for 10 minutes
          retryCount: 3, // Retry failed queries 3 times
        ),
      ),
      child: MaterialApp.router(
        title: 'WeBuddhist',
        theme: AppTheme.lightTheme(locale),
        darkTheme: AppTheme.darkTheme(locale),
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: [
          MaterialLocalizationsBo.delegate,
          CupertinoLocalizationsBo.delegate,
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.all,
        debugShowCheckedModeBanner: false,
        // routerConfig: router,
        routerConfig: router,
        builder:
            (context, child) =>
                ForceUpdateGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
