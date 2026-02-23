import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/notifications/provider/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});
  static const String routeName = '/notifications';

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final hasPermission = state.hasPermission;

    final localizations = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;
    final titleFontSize = languageCode == 'bo' ? 20.0 : 16.0;
    final subtitleFontSize = languageCode == 'bo' ? 18.0 : 14.0;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.notification_settings)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permission Status Card
            if (!hasPermission) ...[
              Card(
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Theme.of(context).colorScheme.error,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.notification_enable_message,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: subtitleFontSize),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final granted =
                              await ref
                                  .read(notificationServiceProvider)
                                  .requestPermission();
                          if (granted) {
                            ref
                                .read(notificationProvider.notifier)
                                .checkPermissionStatus();
                          } else {
                            await openAppSettings();
                          }
                        },
                        child: Text(
                          localizations.enable_notification,
                          style: TextStyle(fontSize: titleFontSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (hasPermission) ...[
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Notifications are enabled',
                          style: TextStyle(fontSize: subtitleFontSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (state.isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
