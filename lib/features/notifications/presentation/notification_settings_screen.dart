import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});
  static const String routeName = '/notifications';

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool _isSchedulingTest = false;

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
      // Re-read every OS-level setting the moment the user returns.
      ref.read(notificationProvider.notifier).refreshStatus().then((_) {
        // If the routine channel is on, make sure every block is scheduled.
        // If it's off, Android simply won't show fires — no cleanup needed.
        final s = ref.read(notificationProvider);
        if (s.hasSystemPermission && s.routineChannelEnabled) {
          ref
              .read(notificationProvider.notifier)
              .resyncRoutineNotifications(ref.read(routineProvider).blocks);
        }
      });
    }
  }

  // ── Toggle handlers ────────────────────────────────────────────────────────

  Future<void> _toggleMaster(bool enable) async {
    if (enable) {
      final granted = await ref
          .read(notificationProvider.notifier)
          .requestEnableNotifications();
      if (!granted) {
        _snack('Permission denied — opening App Settings.');
        await openAppSettings();
      }
    } else {
      _snack('Opening App Settings — turn off notifications there.');
      await openAppSettings();
    }
  }

  Future<void> _toggleRoutineChannel(bool _) async {
    if (Platform.isAndroid) {
      // Android: open the exact notification channel page.
      await ref
          .read(notificationServiceProvider)
          .openChannelSettings(NotificationChannels.routineBlockId);
    } else {
      // iOS: no per-channel control — open the app notification settings page.
      _snack('Opening Settings — manage notifications there.');
      await openAppSettings();
    }
  }

  Future<void> _toggleExactAlarms(bool enable) async {
    if (enable) {
      await ref.read(notificationServiceProvider).openExactAlarmSettings();
    } else {
      _snack('Opening App Settings — disable Alarms & Reminders there.');
      await openAppSettings();
    }
  }

  Future<void> _toggleBattery(bool exempt) async {
    if (exempt) {
      // REQUEST_IGNORE_BATTERY_OPTIMIZATIONS shows a system dialog directly.
      await ref
          .read(notificationServiceProvider)
          .requestBatteryOptimizationExemption();
      ref.read(notificationProvider.notifier).refreshStatus();
    } else {
      _snack('Opening App Settings — re-enable optimization under Battery.');
      await openAppSettings();
    }
  }

  Future<void> _scheduleTestNotification() async {
    final service = ref.read(notificationServiceProvider);
    if (!service.isInitialized) {
      _snack('Notification service not ready.');
      return;
    }
    setState(() => _isSchedulingTest = true);
    try {
      const testId = 9999;
      await service.notificationsPlugin.cancel(testId);
      final at = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 4));
      await service.notificationsPlugin.zonedSchedule(
        testId,
        'Routine Notification Test',
        'Fires at ${_hhmm(at)} — custom sound test',
        at,
        NotificationChannels.routineBlockDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      _snack('Test scheduled for ${_hhmm(at)} — close the app to verify.');
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _isSchedulingTest = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _hhmm(tz.TZDateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final localizations = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final isbo = locale.languageCode == 'bo';
    final ts = isbo ? 20.0 : 16.0;
    final ss = isbo ? 17.0 : 13.5;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.notification_settings)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // ── 1. Master (app-level notification permission) ─────
                _label('Notifications', ts, context),
                _SwitchTile(
                  icon: state.hasSystemPermission
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  title: 'Allow Notifications',
                  subtitle: state.hasSystemPermission
                      ? 'Notifications are enabled for this app'
                      : 'Tap to enable — shows system prompt or opens Settings',
                  value: state.hasSystemPermission,
                  onChanged: _toggleMaster,
                  titleSize: ts,
                  subtitleSize: ss,
                ),

                if (state.hasSystemPermission) ...[
                  const SizedBox(height: 24),

                  // ── 2. Per-channel categories ──────────────────────
                  _label('Categories', ts, context),
                  _SwitchTile(
                    icon: Icons.self_improvement,
                    title: 'Routine Reminders',
                    subtitle: state.routineChannelEnabled
                        ? 'Daily reminders for your practice blocks'
                        : 'Muted — tap to re-enable in system settings',
                    value: state.routineChannelEnabled,
                    onChanged: _toggleRoutineChannel,
                    titleSize: ts,
                    subtitleSize: ss,
                  ),

                  // ── 3. Alarms & Reminders (Android only) ───────────
                  if (Platform.isAndroid) ...[
                    const SizedBox(height: 24),
                    _label('Alarms & Reminders', ts, context),
                    _SwitchTile(
                      icon: Icons.alarm,
                      title: 'Exact Alarms',
                      subtitle: state.canScheduleExactAlarms
                          ? 'Notifications fire at the exact scheduled time'
                          : 'Required on Android 12+ — tap to grant',
                      value: state.canScheduleExactAlarms,
                      onChanged: _toggleExactAlarms,
                      titleSize: ts,
                      subtitleSize: ss,
                    ),
                  ],

                  // ── 4. Battery optimization (Android only) ─────────
                  if (Platform.isAndroid) ...[
                    const SizedBox(height: 24),
                    _label('Battery  ·  Optional', ts, context),
                    _SwitchTile(
                      icon: Icons.battery_charging_full,
                      title: 'Unrestricted Battery',
                      subtitle: state.isBatteryOptimizationExempt
                          ? 'App is exempt from battery optimization — reminders will fire on time even when the app is closed or the phone is idle'
                          : 'Devices such as OnePlus, Xiaomi, Redmi etc may kill background apps. Enable this to keep notifications reliable.',
                      value: state.isBatteryOptimizationExempt,
                      onChanged: _toggleBattery,
                      titleSize: ts,
                      subtitleSize: ss,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── 5. Test ────────────────────────────────────────
                  // _label('Diagnostics', ts, context),
                  // Card(
                  //   margin: EdgeInsets.zero,
                  //   child: ListTile(
                  //     leading: _isSchedulingTest
                  //         ? const SizedBox(
                  //             width: 24,
                  //             height: 24,
                  //             child:
                  //                 CircularProgressIndicator(strokeWidth: 2),
                  //           )
                  //         : Icon(
                  //             Icons.notifications_active,
                  //             color: Theme.of(context).colorScheme.primary,
                  //           ),
                  //     title: Text(
                  //       'Send Test Notification',
                  //       style: TextStyle(
                  //           fontSize: ts, fontWeight: FontWeight.w500),
                  //     ),
                  //     subtitle: Text(
                  //       'Fires in 4 minutes — close the app to verify',
                  //       style: TextStyle(fontSize: ss),
                  //     ),
                  //     trailing: _isSchedulingTest
                  //         ? null
                  //         : const Icon(Icons.chevron_right),
                  //     onTap:
                  //         _isSchedulingTest ? null : _scheduleTestNotification,
                  //     contentPadding: const EdgeInsets.symmetric(
                  //         horizontal: 16, vertical: 4),
                  //   ),
                  // ),
                ],

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _label(String text, double fontSize, BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: fontSize - 3,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.titleSize,
    required this.subtitleSize,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double titleSize;
  final double subtitleSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color:
              value ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle, style: TextStyle(fontSize: subtitleSize)),
        value: value,
        onChanged: onChanged,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
