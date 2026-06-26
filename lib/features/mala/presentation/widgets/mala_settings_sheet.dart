import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart' show connectivityNotifierProvider;
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_settings_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/shared/widgets/app_toggle_switch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MalaSettingsSheet extends ConsumerWidget {
  const MalaSettingsSheet({super.key, required this.mantra});

  final Mantra mantra;

  static Future<void> show(BuildContext context, {required Mantra mantra}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => MalaSettingsSheet(mantra: mantra),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(malaSettingsProvider);
    final settingsNotifier = ref.read(malaSettingsProvider.notifier);
    final isOnline = ref.watch(connectivityNotifierProvider);
    final dividerColor =
        isDark ? AppColors.cardBorderDark : AppColors.grey300;
    const destructiveColor = Color(0xFFB03027);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.goldLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _MalaSettingsTile(
              icon: AppAssets.plus,
              label: l10n.mala_add_to_practice,
              onTap: () => _onAddToPractice(context),
            ),
            Divider(height: 1, color: dividerColor),
            _MalaSettingsTile(
              icon: AppAssets.bookmarkSimple,
              label: l10n.mala_add_to_bookmark,
              onTap: () => _onAddToBookmark(context, ref),
            ),
            Divider(height: 1, color: dividerColor),
            _MalaSettingsToggleTile(
              icon: AppAssets.speakerSimpleHigh,
              label: l10n.mala_sound,
              value: settings.soundEnabled,
              onChanged: settingsNotifier.setSoundEnabled,
            ),
            Divider(height: 1, color: dividerColor),
            _MalaSettingsToggleTile(
              icon: AppAssets.vibrate,
              label: l10n.mala_vibration,
              value: settings.vibrationEnabled,
              onChanged: settingsNotifier.setVibrationEnabled,
            ),
            Divider(height: 1, color: dividerColor),
            _MalaSettingsTile(
              icon: AppAssets.arrowCounterClockwise,
              label: l10n.mala_reset_count,
              labelColor: destructiveColor,
              iconColor: destructiveColor,
              enabled: isOnline,
              onTap: () => _onResetCount(context, ref),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _onAddToPractice(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.mala_action_coming_soon)),
    );
  }

  Future<void> _onAddToBookmark(BuildContext context, WidgetRef ref) async {
    final language = ref.read(contentLanguageProvider);
    final navigator = Navigator.of(context);

    // The controller handles the guest → login-drawer flow and shows its own
    // success/error snackbar, so it must run before the sheet is dismissed
    // (its context drives both). The sheet is closed once the call resolves.
    await BookmarkController(ref: ref, context: context).bookmarkMala(
      mantra.presetId,
      name: mantra.displayTitle(language),
    );

    if (context.mounted) navigator.pop();
  }

  Future<void> _onResetCount(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDestructiveConfirmationDialog(
      context,
      title: l10n.mala_reset_title,
      message: l10n.mala_reset_count_confirm,
      confirmLabel: l10n.mala_reset_confirm,
      cancelLabel: l10n.cancel,
      barrierDismissible: false,
      onConfirmed: () async {
        HapticFeedback.mediumImpact();
        return ref.read(malaCounterProvider(mantra).notifier).resetCount();
      },
    );
    if (!context.mounted) return;
    if (result == true) {
      Navigator.of(context).pop();
    } else if (result == false) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.something_went_wrong)),
      );
    }
  }
}

class _MalaSettingsTile extends StatelessWidget {
  const _MalaSettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = labelColor ?? theme.colorScheme.onSurface;

    return Opacity(
      opacity: enabled ? 1.0 : 0.38,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 24, color: iconColor ?? foreground),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MalaSettingsToggleTile extends StatelessWidget {
  const _MalaSettingsToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: foreground),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
          ),
          AppToggleSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
