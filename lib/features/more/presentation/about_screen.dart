import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String routeName = '/about';

  List<_SocialLink> _buildSocialLinks(AppLocalizations l10n) => [
    _SocialLink(
      icon: PhosphorIconsRegular.linkSimple,
      title: l10n.about_social_website,
      subtitle: 'www.webuddhist.com',
      url: 'https://webuddhist.com/collections',
    ),
    _SocialLink(
      icon: AppAssets.instagram,
      title: 'Instagram',
      subtitle: '@webuddhist',
      url: 'https://www.instagram.com/webuddhist_?igsh=MXEwajM5dmxkbmYyYQ==',
    ),
    _SocialLink(
      icon: AppAssets.facebook,
      title: 'Facebook',
      subtitle: 'facebook.com/webuddhist',
      url: 'https://www.facebook.com/share/1D9u6rMCsy/',
    ),
    _SocialLink(
      icon: AppAssets.twitter,
      title: 'X (Twitter)',
      subtitle: '@webuddhist',
      url: 'https://x.com/WeBuddhist_',
    ),
    _SocialLink(
      icon: AppAssets.youtube,
      title: 'YouTube',
      subtitle: '@webuddhist',
      url: 'https://youtube.com/@we_buddhist?si=Re1GiaGDJIEypIva',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          l10n.about_title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, l10n),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.about_connect_with_us,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSocialList(context, isDarkMode, l10n),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/images/webuddhist_gold.png',
              width: 96,
              height: 96,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 23,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.about_description,
            textAlign: TextAlign.justify,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialList(BuildContext context, bool isDarkMode, AppLocalizations l10n) {
    return Column(
      children:
          _buildSocialLinks(l10n).map((link) {
            return _SocialLinkTile(link: link, isDarkMode: isDarkMode);
          }).toList(),
    );
  }
}

class _SocialLinkTile extends StatelessWidget {
  final _SocialLink link;
  final bool isDarkMode;

  const _SocialLinkTile({required this.link, required this.isDarkMode});

  Future<void> _openUrl() async {
    final uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openUrl,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Icon(link.icon, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        link.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  AppAssets.arrowSquareOut,
                  size: 20,
                  color: AppColors.grey600,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDarkMode ? AppColors.cardBorderDark : AppColors.grey100,
          ),
        ],
      ),
    );
  }

}

class _SocialLink {
  final IconData icon;
  final String title;
  final String subtitle;
  final String url;

  _SocialLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
  });
}
