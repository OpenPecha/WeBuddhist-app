import 'package:audio_service/audio_service.dart';
import 'package:flutter_pecha/core/services/audio/audio_handler.dart';
import 'package:flutter_pecha/features/notifications/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('ServiceProviders');

/// Audio Handler Provider - provides the initialized AudioHandler
/// Returns null if initialization failed
final audioHandlerProvider = Provider<AudioHandler?>((ref) {
  return ref.watch(_audioHandlerStateProvider).valueOrNull;
});

/// Notification Service Provider - provides the initialized NotificationService
/// Returns null if initialization failed
final notificationServiceProvider = Provider<NotificationService?>((ref) {
  return ref.watch(_notificationServiceStateProvider).valueOrNull;
});

/// Internal state provider for AudioHandler initialization
final _audioHandlerStateProvider = FutureProvider<AudioHandler?>((ref) async {
  try {
    _log.info('Initializing AudioService...');
    final handler = await AudioService.init(
      builder: () => AppAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'org.pecha.app.channel.audio',
        androidNotificationChannelName: 'Audio Playback',
        androidStopForegroundOnPause: false,
      ),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _log.severe('AudioService initialization timed out');
        throw Exception('AudioService initialization timed out');
      },
    );
    _log.info('AudioService initialized successfully');
    return handler;
  } catch (e, stackTrace) {
    _log.severe('Error initializing AudioService: $e', e, stackTrace);
    _log.warning(
      'App will continue without audio service. Audio features may not work.',
    );
    // Return null instead of throwing - allows app to continue
    return null;
  }
});

/// Internal state provider for NotificationService initialization
final _notificationServiceStateProvider =
    FutureProvider<NotificationService?>((ref) async {
  try {
    _log.info('Initializing NotificationService...');
    final service = NotificationService();
    await service.initializeWithoutPermissions().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _log.severe('NotificationService initialization timed out');
        throw Exception('NotificationService initialization timed out');
      },
    );
    _log.info('NotificationService initialized successfully');
    return service;
  } catch (e, stackTrace) {
    _log.severe('Error initializing NotificationService: $e', e, stackTrace);
    _log.warning('App will continue without notifications.');
    // Return null instead of throwing - allows app to continue
    return null;
  }
});

/// Provider to check if services are initialized and ready
final servicesReadyProvider = Provider<bool>((ref) {
  final audioReady = ref.watch(_audioHandlerStateProvider);
  final notificationReady = ref.watch(_notificationServiceStateProvider);

  // Services are ready when both have completed loading (success or failure)
  return audioReady.hasValue && notificationReady.hasValue;
});

/// Convenience provider to get typed AudioHandler
final appAudioHandlerProvider = Provider<AppAudioHandler?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler as AppAudioHandler?;
});
