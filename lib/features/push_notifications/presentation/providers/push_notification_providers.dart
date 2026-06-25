import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/push_notifications/application/push_notification_service.dart';
import 'package:flutter_pecha/features/push_notifications/data/repositories/push_messaging_repository_impl.dart';
import 'package:flutter_pecha/features/push_notifications/domain/repositories/push_messaging_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushMessagingRepositoryProvider =
    Provider<PushMessagingRepository>((ref) {
  return PushMessagingRepositoryImpl(dio: ref.watch(dioProvider));
});

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(
    repository: ref.watch(pushMessagingRepositoryProvider),
    storage: ref.watch(localStorageServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Eagerly initializes FCM and feeds auth changes into the service so the
/// device token is registered once the user signs in. Watch for the app
/// lifetime (e.g. in `MyApp.build`).
final pushNotificationBootstrapProvider = Provider<void>((ref) {
  final service = ref.watch(pushNotificationServiceProvider);
  service.initialize();

  void syncAuth() {
    final auth = ref.read(authProvider);
    if (auth.isLoading) return;
    service.onAuthChanged(
      loggedIn: auth.isLoggedIn && !auth.isGuest,
      email: ref.read(userProvider).user?.email,
    );
  }

  // Email loads just after login — listen to both so registration fires once
  // the profile (and its email) resolves.
  ref.listen<AuthState>(authProvider, (_, __) => syncAuth(), fireImmediately: true);
  ref.listen<UserState>(userProvider, (_, __) => syncAuth());
});
