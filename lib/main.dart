import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/cache/cache_service.dart';
import 'package:flutter_pecha/core/config/router/app_router.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/l10n/l10n.dart';
import 'package:flutter_pecha/core/services/service_providers.dart';
import 'package:flutter_pecha/core/theme/theme_notifier.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/services/notification_service.dart';
import 'package:flutter_pecha/features/practice/data/datasources/routine_local_storage.dart';
import 'package:flutter_pecha/features/practice/data/providers/routine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/config/router/go_router.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:fquery/fquery.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/material_localizations_bo.dart';
import 'core/localization/cupertino_localizations_bo.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/config/app_feature_flags.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';

final _logger = AppLogger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup environment-aware logging
  AppLogger.init();

  // Use bundled fonts only — prevent runtime network fetching
  GoogleFonts.config.allowRuntimeFetching = false;

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    _logger.warning('Error loading .env file: $e');
    // Continue app initialization even if .env fails
  }

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

  // Initialize routine local storage (persistent user data, not cache)
  final routineStorage = RoutineLocalStorage();
  try {
    await routineStorage.initialize();
    _logger.info('Routine local storage initialized');
  } catch (e) {
    _logger.warning('Error initializing routine local storage: $e');
  }

  // Create provider container for notification service access
  final container = ProviderContainer(
    overrides: [
      routineLocalStorageProvider.overrideWithValue(routineStorage),
    ],
  );

  // Set the container reference for notifications
  if (!AppFeatureFlags.kComingSoonMode) {
    NotificationService.setContainer(container);
  }

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Initialize services in background via providers
    // Skip in Coming Soon mode - no content to play, no notifications needed
    if (!AppFeatureFlags.kComingSoonMode) {
      ref.watch(audioHandlerProvider);
      ref.watch(notificationServiceProvider);
      NotificationService.setRouter(router);
    }

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
        routerConfig: AppRouter().router,
      ),
    );
  }
}
