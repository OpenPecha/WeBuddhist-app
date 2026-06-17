import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_links_drawer.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupProfileBody extends ConsumerStatefulWidget {
  final GroupProfile profile;
  final bool isDark;
  final ScrollController? scrollController;
  final VoidCallback? onSeriesTap;

  const GroupProfileBody({
    super.key,
    required this.profile,
    required this.isDark,
    this.scrollController,
    this.onSeriesTap,
  });

  @override
  ConsumerState<GroupProfileBody> createState() => _GroupProfileBodyState();
}

class _GroupProfileBodyState extends ConsumerState<GroupProfileBody>
    with SingleTickerProviderStateMixin {
  bool _isDescriptionExpanded = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
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
          if (profile.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTags(profile.tags, isDark),
          ],
          if (profile.description != null &&
              profile.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDescription(profile.description!, isDark),
          ],
          if (orderedLinks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildLinksSummary(orderedLinks, isDark, lineHeight),
          ],
          const SizedBox(height: 20),
          _GroupFollowButton(
            profile: profile,
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildTabBar(isDark),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                return _buildPracticesTab(profile, isDark, lineHeight);
              }
              return _buildAboutTab(profile, isDark, locale.languageCode);
            },
          ),
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
      child: Row(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.title.isNotEmpty)
                  Text(
                    profile.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: lineHeight,
                    ),
                  ),
                if (profile.subTitle != null &&
                    profile.subTitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.subTitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryColor,
                      height: lineHeight,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                _GroupMemberCountText(
                  groupType: profile.groupType,
                  baseCount: profile.memberOrFollowerCount,
                  isDark: isDark,
                  lineHeight: lineHeight,
                ),
              ],
            ),
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

  Widget _buildTags(List<String> tags, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children:
            tags.map((tag) {
              return Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? AppColors.textTertiaryDark : AppColors.grey800,
                ),
              );
            }).toList(),
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

  Widget _buildTabBar(bool isDark) {
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final unselectedColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.grey800 : AppColors.grey300;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: labelColor,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: context.l10n.nav_practice),
            Tab(text: context.l10n.about_title),
          ],
        ),
        Divider(height: 1, thickness: 1, color: dividerColor),
      ],
    );
  }

  Widget _buildPracticesTab(
    GroupProfile profile,
    bool isDark,
    double? lineHeight,
  ) {
    if (profile.series.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children:
          profile.series
              .map((series) => _buildSeriesRow(series, isDark, lineHeight))
              .toList(),
    );
  }

  Widget _buildAboutTab(
    GroupProfile profile,
    bool isDark,
    String languageCode,
  ) {
    final descriptionLong = profile.descriptionLong?.trim();
    if (descriptionLong == null || descriptionLong.isEmpty) {
      return const SizedBox.shrink();
    }

    final bodyFontSize = languageCode == 'bo' ? 18.0 : 15.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: PlanInlineMarkdownView(
        content: descriptionLong,
        fontSize: bodyFontSize,
      ),
    );
  }

  Widget _buildSeriesRow(
    GroupProfileSeries series,
    bool isDark,
    double? lineHeight,
  ) {
    return InkWell(
      onTap: () {
        widget.onSeriesTap?.call();
        context.push('/home/series/${series.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child:
                    series.image != null && !series.image!.isEmpty
                        ? ResponsiveCoverImage(
                          image: series.image,
                          fit: BoxFit.cover,
                          width: 56,
                          height: 56,
                        )
                        : Container(
                          color:
                              isDark
                                  ? AppColors.surfaceVariantDark
                                  : AppColors.grey100,
                          child: Icon(
                            AppAssets.bookOpenText,
                            color:
                                isDark ? AppColors.grey500 : AppColors.grey600,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: lineHeight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (series.subTitle != null &&
                      series.subTitle!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        series.subTitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textSecondary,
                          height: lineHeight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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

class _GroupMemberCountText extends StatelessWidget {
  final GroupType groupType;
  final int baseCount;
  final bool isDark;
  final double? lineHeight;

  const _GroupMemberCountText({
    required this.groupType,
    required this.baseCount,
    required this.isDark,
    this.lineHeight,
  });

  @override
  Widget build(BuildContext context) {
    final count = baseCount.clamp(0, 1 << 31);
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

class _GroupFollowButton extends ConsumerWidget {
  final GroupProfile profile;
  final bool isDark;

  const _GroupFollowButton({
    required this.profile,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followKey = GroupFollowKey(groupId: profile.id, groupType: profile.groupType);
    final followState = ref.watch(groupFollowProvider(followKey));

    final isFollowing = switch (followState) {
      GroupFollowSuccess(isFollowing: final f) => f,
      _ => false,
    };
    final isLoading = followState is GroupFollowLoading;
    final isPage = profile.groupType.isPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed:
              isLoading
                  ? null
                  : () => _onFollowPressed(
                    context,
                    ref,
                    followKey,
                    isFollowing,
                  ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isFollowing
                    ? (isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.grey100)
                    : (isDark ? AppColors.surfaceWhite : AppColors.textPrimary),
            foregroundColor:
                isFollowing
                    ? (isDark ? AppColors.surfaceWhite : AppColors.textPrimary)
                    : (isDark ? AppColors.textPrimary : AppColors.surfaceWhite),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          child:
              isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(
                    isFollowing
                        ? (isPage ? context.l10n.following : context.l10n.joined)
                        : (isPage ? context.l10n.follow : context.l10n.join),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
    );
  }

  Future<void> _onFollowPressed(
    BuildContext context,
    WidgetRef ref,
    GroupFollowKey followKey,
    bool isCurrentlyFollowing,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final notifier = ref.read(groupFollowProvider(followKey).notifier);
    final myGroups = ref.read(myGroupsProvider.notifier);
    final success =
        isCurrentlyFollowing ? await notifier.unfollow() : await notifier.follow();

    if (!success) return;

    if (isCurrentlyFollowing) {
      myGroups.removeGroup(profile.id);
    } else {
      myGroups.addGroup(profile);
    }
  }
}
