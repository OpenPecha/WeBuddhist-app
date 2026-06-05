import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String routeName = '/about';

  static final _socialLinks = [
    _SocialLink(
      icon: FontAwesomeIcons.globe,
      title: 'Website',
      subtitle: 'www.webuddhist.com',
      url: 'https://webuddhist.com/collections',
      useCircleBorder: true,
    ),
    _SocialLink(
      icon: FontAwesomeIcons.instagram,
      title: 'Instagram',
      subtitle: '@webuddhist',
      url: 'https://www.instagram.com/webuddhist_?igsh=MXEwajM5dmxkbmYyYQ==',
    ),
    _SocialLink(
      icon: FontAwesomeIcons.facebook,
      title: 'Facebook',
      subtitle: 'facebook.com/webuddhist',
      url: 'https://www.facebook.com/webuddhist',
      filledBackground: true,
    ),
    _SocialLink(
      icon: FontAwesomeIcons.xTwitter,
      title: 'X (Twitter)',
      subtitle: '@webuddhist',
      url: 'https://www.x.com/webuddhist',
    ),
    _SocialLink(
      icon: FontAwesomeIcons.youtube,
      title: 'YouTube',
      subtitle: '@webuddhist',
      url: 'https://www.youtube.com/@webuddhist',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'About',
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
              _buildHeader(context),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect with us',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSocialList(context, isDarkMode),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/images/webuddhist_gold.png',
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'WeBuddhist',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We help Buddhists do less harm, more good, and know their own mind better by learning, practicing and connecting daily so that all beings become free from suffering and find lasting happiness.',
            textAlign: TextAlign.justify,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialList(BuildContext context, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? AppColors.cardBorderDark : AppColors.grey100,
          ),
        ),
      ),
      child: Column(
        children:
            _socialLinks.map((link) {
              return _SocialLinkTile(link: link, isDarkMode: isDarkMode);
            }).toList(),
      ),
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
                _buildIconContainer(),
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
                  PhosphorIconsRegular.arrowSquareOut,
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

  Widget _buildIconContainer() {
    const double size = 44;
    const double iconSize = 20;

    if (link.filledBackground) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: FaIcon(link.icon, size: iconSize, color: Colors.white),
        ),
      );
    }

    if (link.useCircleBorder) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.grey300, width: 1.5),
        ),
        child: Center(child: FaIcon(link.icon, size: iconSize)),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey300, width: 1.5),
      ),
      child: Center(child: FaIcon(link.icon, size: iconSize)),
    );
  }
}

class _SocialLink {
  final FaIconData icon;
  final String title;
  final String subtitle;
  final String url;
  final bool filledBackground;
  final bool useCircleBorder;

  _SocialLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
    this.filledBackground = false,
    this.useCircleBorder = false,
  });
}
