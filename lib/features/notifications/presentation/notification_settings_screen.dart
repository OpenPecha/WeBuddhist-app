import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
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
  static const int _testNotifId = 9999;

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
        // Engine short-circuits when master is off or permission is missing.
        ref
            .read(notificationSyncEngineProvider)
            .sync(trigger: SyncTrigger.appResume);
      });
    }
  }

  // ── Toggle handlers ────────────────────────────────────────────────────────

  Future<void> _toggleMaster(bool enable) async {
    final result = await ref
        .read(notificationProvider.notifier)
        .toggleMaster(enable);
    if (!mounted) return;
    switch (result) {
      case NotificationToggleResult.permissionDenied:
        _snack(
          AppLocalizations.of(context)!.notification_snack_permission_denied,
        );
        await openAppSettings();
      case NotificationToggleResult.error:
        _snack(AppLocalizations.of(context)!.something_went_wrong);
      case NotificationToggleResult.success:
        break;
    }
  }

  Future<void> _toggleRoutine(bool enable) async {
    final result = await ref
        .read(notificationProvider.notifier)
        .toggleRoutine(enable);
    if (!mounted) return;
    if (result == NotificationToggleResult.error) {
      _snack(AppLocalizations.of(context)!.something_went_wrong);
    }
  }

  Future<void> _toggleRecitation(bool enable) async {
    final result = await ref
        .read(notificationProvider.notifier)
        .toggleRecitation(enable);
    if (!mounted) return;
    if (result == NotificationToggleResult.error) {
      _snack(AppLocalizations.of(context)!.something_went_wrong);
    }
  }

  Future<void> _togglePractice(bool enable) async {
    final result = await ref
        .read(notificationProvider.notifier)
        .togglePractice(enable);
    if (!mounted) return;
    if (result == NotificationToggleResult.error) {
      _snack(AppLocalizations.of(context)!.something_went_wrong);
    }
  }

  Future<void> _toggleExactAlarms(bool enable) async {
    if (enable) {
      await ref.read(notificationServiceProvider).openExactAlarmSettings();
    } else {
      _snack(
        AppLocalizations.of(
          context,
        )!.notification_snack_disable_alarms_in_settings,
      );
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
    if (!ref.read(notificationProvider).appMasterEnabled) {
      _snack('Notifications are disabled — turn them on first.');
      return;
    }
    final service = ref.read(notificationServiceProvider);
    if (!service.isInitialized) {
      _snack('Notification service not ready.');
      return;
    }
    setState(() => _isSchedulingTest = true);
    try {
      await service.notificationsPlugin.cancel(_testNotifId);
      final at = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 4));
      await service.notificationsPlugin.zonedSchedule(
        _testNotifId,
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
      builder:
          (ctx) => AlertDialog(
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _hhmm(tz.TZDateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final localizations = AppLocalizations.of(context)!;
    final ts = getLocalizedFontSize(AppTextSize.body);
    final ss = getLocalizedFontSize(AppTextSize.label);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        centerTitle: true,
        title: Text(
          localizations.notification_settings,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body:
          state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // ── 1. Master toggle ──────────────────────────────────
                    _SwitchTile(
                      title: localizations.notification_allow_title,
                      subtitle:
                          !state.appMasterEnabled
                              ? localizations.notification_allow_subtitle_paused
                              : state.hasSystemPermission
                              ? localizations
                                  .notification_allow_subtitle_enabled
                              : localizations
                                  .notification_allow_subtitle_disabled,
                      value: state.appMasterEnabled,
                      onChanged: _toggleMaster,
                      titleSize: ts,
                      subtitleSize: ss,
                    ),

                    if (state.appMasterEnabled &&
                        state.hasSystemPermission) ...[
                      // ── 2. Sub-toggles ────────────────────────────────

                      // Routine (plan) reminders
                      _SwitchTile(
                        title: localizations.notification_routine_title,
                        subtitle:
                            state.appRoutineEnabled
                                ? localizations
                                    .notification_routine_subtitle_enabled
                                : localizations
                                    .notification_routine_subtitle_disabled,
                        value: state.appRoutineEnabled,
                        onChanged: _toggleRoutine,
                        titleSize: ts,
                        subtitleSize: ss,
                      ),

                      // Recitation reminders
                      _SwitchTile(
                        title: localizations.notification_recitation_title,
                        subtitle:
                            state.appRecitationEnabled
                                ? localizations
                                    .notification_recitation_subtitle_enabled
                                : localizations
                                    .notification_recitation_subtitle_disabled,
                        value: state.appRecitationEnabled,
                        onChanged: _toggleRecitation,
                        titleSize: ts,
                        subtitleSize: ss,
                      ),

                      // Practice (mala) reminders
                      _SwitchTile(
                        title: localizations.notification_practice_title,
                        subtitle:
                            state.appPracticeEnabled
                                ? localizations
                                    .notification_practice_subtitle_enabled
                                : localizations
                                    .notification_practice_subtitle_disabled,
                        value: state.appPracticeEnabled,
                        onChanged: _togglePractice,
                        titleSize: ts,
                        subtitleSize: ss,
                      ),

                      // ── 3. Battery optimization (Android only) ─────────
                      if (Platform.isAndroid)
                        _SwitchTile(
                          title: localizations.notification_battery_title,
                          subtitle:
                              state.isBatteryOptimizationExempt
                                  ? localizations
                                      .notification_battery_subtitle_enabled
                                  : localizations
                                      .notification_battery_subtitle_disabled,
                          value: state.isBatteryOptimizationExempt,
                          onChanged: _toggleBattery,
                          titleSize: ts,
                          subtitleSize: ss,
                          onInfo:
                              () => _showInfoDialog(
                                localizations.notification_battery_info_title,
                                localizations.notification_battery_info_body,
                              ),
                        ),
                    ],
                  ],
                ),
              ),
    );
  }
}

class _AppToggle extends StatelessWidget {
  const _AppToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 32,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value ? const Color(0xFF196BF1) : const Color(0xFFADADAD),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceWhite,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.titleSize,
    required this.subtitleSize,
    this.onInfo,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double titleSize;
  final double subtitleSize;
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (onInfo != null)
                      GestureDetector(
                        onTap: onInfo,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.info_outline,
                            size: 17,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _AppToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
