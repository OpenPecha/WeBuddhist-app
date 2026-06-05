import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/theme_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  final _supportedLocales = const [
    Locale(AppConfig.englishLanguageCode),
    Locale(AppConfig.chineseLanguageCode),
    Locale(AppConfig.tibetanLanguageCode),
  ];

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case AppConfig.englishLanguageCode:
        return 'English';
      case AppConfig.chineseLanguageCode:
        return '中文';
      case AppConfig.tibetanLanguageCode:
        return 'བོད་ཡིག';
      default:
        return locale.languageCode;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final localizations = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          localizations.nav_settings,
          strutStyle: context.tibetanStrutStyle(
            Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24,
          ),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Personalisation Section
            _buildSectionHeader(context, 'PERSONALISATION'),
            const SizedBox(height: 12),
            if (authState.isLoggedIn && !authState.isGuest)
              _buildSettingsRow(
                context,
                icon: PhosphorIconsRegular.user,
                title: 'Edit profile',
                onTap: () => context.push(AppRoutes.profile),
              ),
            _buildLanguageRow(context, ref, locale),
            _buildNotificationRow(context),
            _buildThemeToggleRow(context, ref, isDarkMode),
            const SizedBox(height: 24),

            // More Section
            _buildSectionHeader(context, 'MORE'),
            const SizedBox(height: 12),
            _buildSettingsRow(
              context,
              icon: PhosphorIconsRegular.info,
              title: 'About',
              onTap: () => context.push(AppRoutes.about),
            ),
            _buildSettingsRow(
              context,
              icon: PhosphorIconsRegular.gavel,
              title: 'Legal',
              onTap: () => context.push(AppRoutes.privacyPolicy),
            ),
            _buildSettingsRow(
              context,
              icon: PhosphorIconsRegular.chatText,
              title: 'Feedback',
              trailingIcon: PhosphorIconsRegular.arrowSquareOut,
              onTap: () async {
                final url =
                    "https://app-webuddhist.ideas.userback.io/p/5omSMHB8A9VMUrD6vLrE";
                await launchUrl(Uri.parse(url));
              },
            ),
            const SizedBox(height: 24),

            // Account Section
            _buildSectionHeader(context, 'ACCOUNT'),
            const SizedBox(height: 12),
            if (!authState.isLoggedIn || authState.isGuest) ...[
              _buildSettingsRow(
                context,
                icon: PhosphorIconsRegular.signIn,
                title: localizations.sign_in,
                onTap: () => LoginDrawer.show(context, ref),
              ),
            ] else ...[
              _buildSettingsRow(
                context,
                icon: PhosphorIconsRegular.signOut,
                title: localizations.logout,
                onTap: () => _showLogoutDialog(context, ref),
                isDestructive: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleRow(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
  ) {
    return _buildSettingsRow(
      context,
      icon: PhosphorIconsRegular.sun,
      title: 'Theme',
      onTap: () {
        ref
            .read(themeModeProvider.notifier)
            .setTheme(isDarkMode ? ThemeMode.light : ThemeMode.dark);
      },
      trailing: _ThemeToggle(
        isDarkMode: isDarkMode,
        onChanged: (value) {
          ref
              .read(themeModeProvider.notifier)
              .setTheme(value ? ThemeMode.dark : ThemeMode.light);
        },
      ),
    );
  }

  Widget _buildNotificationRow(BuildContext context) {
    return _buildSettingsRow(
      context,
      icon: PhosphorIconsRegular.bellRinging,
      title: 'Notification',
      onTap: () => context.push(NotificationSettingsScreen.routeName),
    );
  }

  Widget _buildLanguageRow(BuildContext context, WidgetRef ref, Locale locale) {
    final currentLanguageName = _getLanguageName(locale);
    return InkWell(
      onTap: () => _showLanguageBottomSheet(context, ref, locale),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              PhosphorIconsRegular.globe,
              size: 24,
              color: Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                currentLanguageName,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 24,
              color: AppColors.grey600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    IconData? trailingIcon,
    bool isDestructive = false,
  }) {
    final color =
        isDestructive ? Colors.red.shade600 : Theme.of(context).iconTheme.color;
    final textColor = isDestructive ? Colors.red.shade600 : null;

    final rowContent = Row(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: textColor),
          ),
        ),
        if (trailing == null)
          Icon(
            trailingIcon ?? PhosphorIconsRegular.caretRight,
            size: 24,
            color: isDestructive ? Colors.red.shade600 : AppColors.grey600,
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: rowContent,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.grey600,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _showLanguageBottomSheet(
    BuildContext context,
    WidgetRef ref,
    Locale? currentLocale,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDarkMode ? AppColors.surfaceDark : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    child: Container(
                      width: 80,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.grey600 : Colors.black,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Language options container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode ? AppColors.cardDark : AppColors.grey100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          _supportedLocales.map((localeItem) {
                            final isSelected =
                                (currentLocale ??
                                    Localizations.localeOf(context)) ==
                                localeItem;
                            return _buildLanguageOption(
                              context,
                              ref,
                              localeItem,
                              isSelected,
                              isDarkMode,
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    Locale localeItem,
    bool isSelected,
    bool isDarkMode,
  ) {
    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(localeItem);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (isDarkMode
                      ? AppColors.surfaceVariantDark
                      : AppColors.goldAccent)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _getLanguageName(localeItem),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text(
              localizations.logout,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            content: Text(
              localizations.logout_confirmation,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                ),
                child: Text(localizations.logout),
              ),
            ],
          ),
    );
  }
}

/// Custom theme toggle widget with sun and moon icons
class _ThemeToggle extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const _ThemeToggle({required this.isDarkMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isDarkMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 32,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDarkMode ? AppColors.grey800 : AppColors.goldAccent,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode ? AppColors.grey600 : AppColors.surfaceWhite,
            ),
          ),
        ),
      ),
    );
  }
}
