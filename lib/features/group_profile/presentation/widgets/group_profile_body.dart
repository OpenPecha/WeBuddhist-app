import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_links_drawer.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupProfileBody extends ConsumerStatefulWidget {
  final GroupProfile profile;
  final bool isDark;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;

  const GroupProfileBody({
    super.key,
    required this.profile,
    required this.isDark,
    this.scrollController,
    this.physics,
  });

  @override
  ConsumerState<GroupProfileBody> createState() => _GroupProfileBodyState();
}

class _GroupProfileBodyState extends ConsumerState<GroupProfileBody> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final lineHeight = getLineHeight(locale.languageCode);
    final profile = widget.profile;
    final isDark = widget.isDark;

    final orderedLinks = GroupProfileLinksDrawer.orderedLinks(
      profile.socialLinks,
    );

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics:
          widget.physics ??
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.bannerUrl != null && profile.bannerUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImageWidget(
                    key: ValueKey(profile.bannerUrl),
                    imageUrl: profile.bannerUrl,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color:
                          isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.grey100,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildProfileHeader(profile, isDark, lineHeight),
          if (orderedLinks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildLinksSummary(orderedLinks, isDark, lineHeight),
          ],
          if (profile.description != null &&
              profile.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDescription(profile.description!, isDark),
          ],
          const SizedBox(height: 24),
          _buildAboutContent(profile),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    GroupProfile profile,
    bool isDark,
    double? lineHeight,
  ) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child:
                      profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageWidget(
                            key: ValueKey(profile.avatarUrl),
                            imageUrl: profile.avatarUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorWidget: _buildAvatarFallback(isDark),
                          )
                          : _buildAvatarFallback(isDark),
                ),
              ),
              const SizedBox(width: 12),
              if (profile.title.isNotEmpty)
                Expanded(
                  child: Text(
                    profile.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: lineHeight,
                    ),
                  ),
                ),
            ],
          ),
          if (profile.subTitle != null &&
              profile.subTitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.subTitle!,
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
                height: lineHeight,
              ),
            ),
            const SizedBox(height: 4),
          ] else
            const SizedBox(height: 8),
          _GroupMemberCountText(
            groupId: profile.id,
            groupType: profile.groupType,
            baseCount: profile.memberOrFollowerCount,
            isDark: isDark,
            lineHeight: lineHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(bool isDark) {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.usersThree,
        size: 22,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }

  Widget _buildDescription(String description, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap:
            () => setState(
              () => _isDescriptionExpanded = !_isDescriptionExpanded,
            ),
        behavior: HitTestBehavior.opaque,
        child: Text(
          description,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          maxLines: _isDescriptionExpanded ? null : 6,
          overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildLinksSummary(
    List<GroupProfileSocialLink> links,
    bool isDark,
    double? lineHeight,
  ) {
    final primaryLink = links.first;
    final moreCount = links.length - 1;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: () {
          if (moreCount > 0) {
            GroupProfileLinksDrawer.show(context, links);
          } else {
            _launchUrl(primaryLink.url);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Icon(AppAssets.linkSimple, size: 18, color: secondaryColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    height: lineHeight,
                  ),
                  children: [
                    TextSpan(text: primaryLink.url),
                    if (moreCount > 0)
                      TextSpan(
                        text:
                            ' ${context.l10n.group_and_more_links(moreCount)}',
                        style: TextStyle(color: secondaryColor),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutContent(GroupProfile profile) {
    final descriptionLong = profile.descriptionLong?.trim();
    if (descriptionLong == null || descriptionLong.isEmpty) {
      return const SizedBox.shrink();
    }

    final bodyFontSize = getLocalizedFontSize(AppTextSize.body);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: PlanInlineMarkdownView(
        content: descriptionLong,
        fontSize: bodyFontSize,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

class _GroupMemberCountText extends ConsumerWidget {
  final String groupId;
  final GroupType groupType;
  final int baseCount;
  final bool isDark;
  final double? lineHeight;

  const _GroupMemberCountText({
    required this.groupId,
    required this.groupType,
    required this.baseCount,
    required this.isDark,
    this.lineHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followKey = GroupFollowKey(groupId: groupId, groupType: groupType);
    final followState = ref.watch(groupFollowProvider(followKey));
    final delta = switch (followState) {
      GroupFollowSuccess(countDelta: final d) => d,
      _ => 0,
    };
    final count = (baseCount + delta).clamp(0, 1 << 31);
    final formattedCount = NumberFormat.decimalPattern(
      intlFormatLocaleOf(context),
    ).format(count);
    final countLabel =
        groupType.isPage
            ? (count == 1
                ? context.l10n.group_follower
                : context.l10n.group_followers)
            : (count == 1
                ? context.l10n.group_member
                : context.l10n.group_members);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          height: lineHeight,
        ),
        children: [
          TextSpan(
            text: formattedCount,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' $countLabel'),
        ],
      ),
    );
  }
}
