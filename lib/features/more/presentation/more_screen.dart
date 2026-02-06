import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/theme_notifier.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/auth/application/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
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
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final localizations = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Title
            Text(
              localizations.nav_settings,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Profile Section
            if (authState.isLoggedIn && !authState.isGuest) ...[
              _buildProfileSection(context, ref),
              const SizedBox(height: 32),
            ],

            // Appearance Section
            _buildSectionHeader(context, localizations.settings_appearance),
            const SizedBox(height: 12),
            _buildThemeToggleRow(context, ref, isDarkMode, localizations),
            const SizedBox(height: 24),

            // Language Section
            _buildSectionHeader(context, localizations.language),
            const SizedBox(height: 12),
            _buildLanguageRow(context, ref, locale),
            const SizedBox(height: 24),

            // Account Section
            _buildSectionHeader(context, localizations.settings_account),
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
              ),
            ],
            const SizedBox(height: 16),
            _buildSettingsRow(
              context,
              icon: PhosphorIconsRegular.chatCircleText,
              title: localizations.feedback_wishlist,
              onTap: () async {
                final url =
                    "https://app-webuddhist.ideas.userback.io/p/5omSMHB8A9VMUrD6vLrE";
                await launchUrl(Uri.parse(url));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).user;
    final avatarUrl = user?.avatarUrl ?? '';

    return Row(
      children: [
        Hero(
          tag: 'profile-avatar',
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.grey300,
            backgroundImage:
                avatarUrl.isNotEmpty
                    ? avatarUrl.cachedNetworkImageProvider
                    : null,
            child:
                avatarUrl.isEmpty
                    ? Icon(
                      PhosphorIconsRegular.user,
                      size: 40,
                      color: AppColors.grey600,
                    )
                    : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.fullName ?? 'User',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggleRow(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
    AppLocalizations localizations,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isDarkMode ? localizations.themeDark : localizations.themeLight,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        _ThemeToggle(
          isDarkMode: isDarkMode,
          onChanged: (value) {
            ref
                .read(themeModeProvider.notifier)
                .setTheme(value ? ThemeMode.dark : ThemeMode.light);
          },
        ),
      ],
    );
  }

  Widget _buildLanguageRow(BuildContext context, WidgetRef ref, Locale locale) {
    return InkWell(
      onTap: () => _showLanguageBottomSheet(context, ref, locale),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                _getLanguageName(locale),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 20,
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).iconTheme.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        ),
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
        child: Stack(
          children: [
            // Sun icon (visible in light mode, on the left)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: isDarkMode ? 32 : 0,
              top: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isDarkMode ? 0.0 : 1.0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceWhite,
                  ),
                  child: Center(
                    child: Icon(
                      PhosphorIconsRegular.sun,
                      size: 18,
                      color: Colors.amber.shade600,
                    ),
                  ),
                ),
              ),
            ),
            // Moon icon (visible in dark mode, on the right)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              right: isDarkMode ? 0 : 32,
              top: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isDarkMode ? 1.0 : 0.0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.grey600,
                  ),
                  child: Center(
                    child: Icon(
                      PhosphorIconsFill.cloudMoon,
                      size: 18,
                      color: AppColors.surfaceDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
