import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupProfileLinksDrawer extends StatelessWidget {
  final List<GroupProfileSocialLink> links;

  const GroupProfileLinksDrawer({super.key, required this.links});

  static Future<void> show(
    BuildContext context,
    List<GroupProfileSocialLink> links,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => GroupProfileLinksDrawer(links: links),
    );
  }

  static List<GroupProfileSocialLink> orderedLinks(
    List<GroupProfileSocialLink> links,
  ) {
    final website =
        links.where((l) => l.platform.toLowerCase() == 'website').toList();
    final others =
        links.where((l) => l.platform.toLowerCase() != 'website').toList();
    return [...website, ...others];
  }

  static IconData iconForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return AppAssets.instagram;
      case 'facebook':
        return AppAssets.facebook;
      case 'twitter':
      case 'x':
        return AppAssets.twitter;
      case 'youtube':
        return AppAssets.youtube;
      case 'tiktok':
        return AppAssets.tiktok;
      case 'linkedin':
        return AppAssets.linkedin;
      case 'website':
        return AppAssets.linkSimple;
      default:
        return AppAssets.link;
    }
  }

  static String labelForPlatform(String platform, BuildContext context) {
    switch (platform.toLowerCase()) {
      case 'website':
        return context.l10n.about_social_website;
      case 'instagram':
        return 'Instagram';
      case 'facebook':
        return 'Facebook';
      case 'twitter':
      case 'x':
        return 'X (Twitter)';
      case 'youtube':
        return 'YouTube';
      case 'tiktok':
        return 'TikTok';
      case 'linkedin':
        return 'LinkedIn';
      default:
        return platform.isNotEmpty
            ? platform[0].toUpperCase() + platform.substring(1)
            : context.l10n.about_social_website;
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordered = orderedLinks(links);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.group_links_title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: ordered.length,
            separatorBuilder:
                (_, __) => Divider(
                  height: 1,
                  color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
                ),
            itemBuilder: (context, index) {
              final link = ordered[index];
              return _LinkTile(
                icon: iconForPlatform(link.platform),
                title: labelForPlatform(link.platform, context),
                subtitle: link.url,
                isDark: isDark,
                onTap: () => _launchUrl(link.url),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
