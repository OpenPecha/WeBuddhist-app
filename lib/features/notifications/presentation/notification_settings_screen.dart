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
      ref.read(notificationProvider.notifier).refreshStatus().then((_) {
        final s = ref.read(notificationProvider);
        if (s.appMasterEnabled && s.hasSystemPermission) {
          ref
              .read(notificationProvider.notifier)
              .resyncRoutineNotifications(ref.read(routineProvider).blocks);
        }
      });
    }
  }

  // ── Toggle handlers ────────────────────────────────────────────────────────

  Future<void> _toggleMaster(bool enable) async {
    final result =
        await ref.read(notificationProvider.notifier).toggleMaster(enable);
    if (!mounted) return;
    switch (result) {
      case NotificationToggleResult.permissionDenied:
        _snack(AppLocalizations.of(context)!.notification_snack_permission_denied);
        await openAppSettings();
      case NotificationToggleResult.error:
        _snack(AppLocalizations.of(context)!.something_went_wrong);
      case NotificationToggleResult.success:
        break;
    }
  }

  Future<void> _toggleRoutine(bool enable) async {
    final result =
        await ref.read(notificationProvider.notifier).toggleRoutine(enable);
    if (!mounted) return;
    if (result == NotificationToggleResult.error) {
      _snack(AppLocalizations.of(context)!.something_went_wrong);
    }
  }

  Future<void> _toggleRecitation(bool enable) async {
    final result =
        await ref.read(notificationProvider.notifier).toggleRecitation(enable);
    if (!mounted) return;
    if (result == NotificationToggleResult.error) {
      _snack(AppLocalizations.of(context)!.something_went_wrong);
    }
  }

  Future<void> _toggleExactAlarms(bool enable) async {
    if (enable) {
      await ref.read(notificationServiceProvider).openExactAlarmSettings();
    } else {
      _snack(AppLocalizations.of(context)!.notification_snack_disable_alarms_in_settings);
      await openAppSettings();
    }
  }

  Future<void> _toggleBattery(bool exempt) async {
    if (exempt) {
      await ref
          .read(notificationServiceProvider)
          .requestBatteryOptimizationExemption();
      ref.read(notificationProvider.notifier).refreshStatus();
    } else {
      _snack(AppLocalizations.of(context)!.notification_snack_battery_reenable);
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

  void _showInfoDialog(String title, String body) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.got_it),
          ),
        ],
      ),
    );
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
                // ── 1. Master toggle ──────────────────────────────────
                _label(localizations.notification_section_notifications, ts, context),
                _SwitchTile(
                  icon: state.appMasterEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  title: localizations.notification_allow_title,
                  subtitle: !state.appMasterEnabled
                      ? localizations.notification_allow_subtitle_paused
                      : state.hasSystemPermission
                          ? localizations.notification_allow_subtitle_enabled
                          : localizations.notification_allow_subtitle_disabled,
                  value: state.appMasterEnabled,
                  onChanged: _toggleMaster,
                  titleSize: ts,
                  subtitleSize: ss,
                ),

                if (state.appMasterEnabled && state.hasSystemPermission) ...[
                  const SizedBox(height: 24),

                  // ── 2. Sub-toggles ────────────────────────────────
                  _label(localizations.notification_section_categories, ts, context),

                  // Routine (plan) reminders
                  _SwitchTile(
                    icon: Icons.self_improvement,
                    title: localizations.notification_routine_title,
                    subtitle: state.appRoutineEnabled
                        ? localizations.notification_routine_subtitle_enabled
                        : localizations.notification_routine_subtitle_disabled,
                    value: state.appRoutineEnabled,
                    onChanged: _toggleRoutine,
                    titleSize: ts,
                    subtitleSize: ss,
                  ),

                  const SizedBox(height: 8),

                  // Recitation reminders
                  _SwitchTile(
                    icon: Icons.menu_book_outlined,
                    title: localizations.notification_recitation_title,
                    subtitle: state.appRecitationEnabled
                        ? localizations.notification_recitation_subtitle_enabled
                        : localizations.notification_recitation_subtitle_disabled,
                    value: state.appRecitationEnabled,
                    onChanged: _toggleRecitation,
                    titleSize: ts,
                    subtitleSize: ss,
                  ),

                  // ── 3. Alarms & Reminders (Android only) ───────────
                  // if (Platform.isAndroid) ...[
                  //   const SizedBox(height: 24),
                  //   _label(localizations.notification_section_alarms, ts, context),
                  //   _SwitchTile(
                  //     icon: Icons.alarm,
                  //     title: localizations.notification_alarms_title,
                  //     subtitle: state.canScheduleExactAlarms
                  //         ? localizations.notification_alarms_subtitle_enabled
                  //         : localizations.notification_alarms_subtitle_disabled,
                  //     value: state.canScheduleExactAlarms,
                  //     onChanged: _toggleExactAlarms,
                  //     titleSize: ts,
                  //     subtitleSize: ss,
                  //     onInfo: () => _showInfoDialog(
                  //       localizations.notification_alarms_info_title,
                  //       localizations.notification_alarms_info_body,
                  //     ),
                  //   ),
                  // ],

                  // ── 4. Battery optimization (Android only) ─────────
                  if (Platform.isAndroid) ...[
                    const SizedBox(height: 24),
                    _label(localizations.notification_section_battery, ts, context),
                    _SwitchTile(
                      icon: Icons.battery_charging_full,
                      title: localizations.notification_battery_title,
                      subtitle: state.isBatteryOptimizationExempt
                          ? localizations.notification_battery_subtitle_enabled
                          : localizations.notification_battery_subtitle_disabled,
                      value: state.isBatteryOptimizationExempt,
                      onChanged: _toggleBattery,
                      titleSize: ts,
                      subtitleSize: ss,
                      onInfo: () => _showInfoDialog(
                        localizations.notification_battery_info_title,
                        localizations.notification_battery_info_body,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
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
    this.onInfo,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double titleSize;
  final double subtitleSize;
  /// When provided an ⓘ icon button appears next to the title.
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: value ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                    fontSize: titleSize, fontWeight: FontWeight.w500),
              ),
            ),
            if (onInfo != null)
              InkWell(
                onTap: onInfo,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.info_outline,
                    size: 17,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
          ],
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
