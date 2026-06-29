import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_links_drawer.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_members_tab.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupProfileBody extends ConsumerStatefulWidget {
  final GroupProfile profile;
  final bool isDark;
  final VoidCallback? onSeriesTap;

  const GroupProfileBody({
    super.key,
    required this.profile,
    required this.isDark,
    this.onSeriesTap,
  });

  @override
  ConsumerState<GroupProfileBody> createState() => _GroupProfileBodyState();
}

class _GroupProfileBodyState extends ConsumerState<GroupProfileBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int get _tabCount {
    var count = 2;
    if (_hasAboutContent(widget.profile)) count++;
    return count;
  }

  int get _membersTabIndex => 1;

  bool _hasAboutContent(GroupProfile profile) {
    final hasBanner = profile.bannerUrl != null && profile.bannerUrl!.isNotEmpty;
    final descriptionLong = profile.descriptionLong?.trim();
    return hasBanner ||
        (descriptionLong != null && descriptionLong.isNotEmpty);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
    );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileHeader(profile, isDark, lineHeight),
        if (orderedLinks.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildLinksSummary(orderedLinks, isDark, lineHeight),
        ],
        const SizedBox(height: 20),
        _GroupFollowButton(profile: profile, isDark: isDark),
        const SizedBox(height: 24),
        _buildTabBar(isDark, profile),
        Expanded(
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final tabIndex = _tabController.index;
              if (tabIndex == 0) {
                return _buildPracticesTab(profile, isDark, lineHeight);
              }
              if (tabIndex == _membersTabIndex) {
                return GroupProfileMembersTab(
                  groupId: profile.id,
                  groupType: profile.groupType,
                  isDark: isDark,
                  lineHeight: lineHeight,
                );
              }
              return _buildAboutTab(profile, isDark, locale.languageCode);
            },
          ),
        ),
      ],
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
          ],
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

  Widget _buildTabBar(bool isDark, GroupProfile profile) {
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final dividerColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final hasAbout = _hasAboutContent(profile);
    final membersTabLabel =
        profile.groupType.isPage
            ? context.l10n.group_tab_followers
            : context.l10n.group_tab_members;

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
            Tab(text: membersTabLabel),
            if (hasAbout) Tab(text: context.l10n.about_title),
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: profile.series.length,
      itemBuilder: (context, index) {
        return _buildSeriesCard(
          profile.series[index],
          profile,
          isDark,
          lineHeight,
        );
      },
    );
  }

  Widget _buildAboutTab(
    GroupProfile profile,
    bool isDark,
    String languageCode,
  ) {
    final descriptionLong = profile.descriptionLong?.trim();
    final hasBanner = profile.bannerUrl != null && profile.bannerUrl!.isNotEmpty;
    final hasDescription =
        descriptionLong != null && descriptionLong.isNotEmpty;

    if (!hasBanner && !hasDescription) {
      return const SizedBox.shrink();
    }

    final bodyFontSize = getLocalizedFontSize(AppTextSize.body);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBanner) ...[
            ClipRRect(
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
            if (hasDescription) const SizedBox(height: 20),
          ],
          if (hasDescription)
            PlanInlineMarkdownView(
              content: descriptionLong,
              fontSize: bodyFontSize,
            ),
        ],
      ),
    );
  }

  Widget _buildSeriesCard(
    GroupProfileSeries series,
    GroupProfile profile,
    bool isDark,
    double? lineHeight,
  ) {
    final hasImage = series.image != null && !series.image!.isEmpty;
    final hasSubTitle =
        series.subTitle != null && series.subTitle!.trim().isNotEmpty;
    // Show the entry point unless the series is already bound to this group.
    final showPracticeWithUs = series.seriesPartnerId != profile.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          widget.onSeriesTap?.call();
          context.push('/home/series/${series.id}');
        },
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      ResponsiveCoverImage(
                        image: series.image,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        color:
                            isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.grey100,
                        child: Icon(
                          AppAssets.bookOpenText,
                          size: 40,
                          color: isDark ? AppColors.grey500 : AppColors.grey600,
                        ),
                      ),
                    if (showPracticeWithUs)
                      Center(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _onPracticeWithUs(series, profile),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWhite,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                context.l10n.group_practice_with_us,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: lineHeight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasSubTitle)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          series.subTitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textSecondary,
                            height: lineHeight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Enrolls the user in [series] bound to this [profile]'s group, then routes
  /// to the edit-routine screen so the newly enrolled plans are prefilled.
  Future<void> _onPracticeWithUs(
    GroupProfileSeries series,
    GroupProfile profile,
  ) async {
    final auth = ref.read(authProvider);
    if (auth.isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }

    widget.onSeriesTap?.call();

    final notifier = ref.read(seriesEnrollmentProvider(series.id).notifier);
    final ok = await notifier.enroll(
      groupId: profile.id,
      autoEnrollNext: true,
    );
    if (!mounted) return;

    if (ok) {
      context.pushNamed('edit-routine', extra: {'enrollSeriesId': series.id});
    } else {
      final state = ref.read(seriesEnrollmentProvider(series.id));
      final message =
          state is SeriesEnrollmentFailure
              ? state.failure.message
              : context.l10n.something_went_wrong;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
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
}

class _GroupFollowButton extends ConsumerWidget {
  final GroupProfile profile;
  final bool isDark;

  const _GroupFollowButton({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followKey = GroupFollowKey(
      groupId: profile.id,
      groupType: profile.groupType,
    );
    final followState = ref.watch(groupFollowProvider(followKey));

    final isFollowing = switch (followState) {
      GroupFollowSuccess(isFollowing: final f) => f,
      _ => false,
    };
    final isLoading = followState is GroupFollowLoading;
    final isPage = profile.groupType.isPage;
    const fontSize = 16.0;
    final locale = Localizations.localeOf(context);
    final isTibetan = context.isTibetanLocale;
    final buttonHeight = isTibetan ? 52.0 : 48.0;
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: Size(0, buttonHeight),
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isTibetan ? 10 : 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child:
          isFollowing
              ? Row(
                children: [
                  Expanded(
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
                      style: buttonStyle.copyWith(
                        backgroundColor: WidgetStatePropertyAll(
                          isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.grey100,
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          isDark
                              ? AppColors.surfaceWhite
                              : AppColors.textPrimary,
                        ),
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                isPage
                                    ? context.l10n.following
                                    : context.l10n.joined,
                                textAlign: TextAlign.center,
                                strutStyle: context.tibetanStrutStyle(fontSize),
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: getSystemFontFamily(
                                    locale.languageCode,
                                  ),
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: buttonStyle.copyWith(
                        backgroundColor: WidgetStatePropertyAll(
                          isDark
                              ? AppColors.surfaceWhite
                              : AppColors.textPrimary,
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          isDark
                              ? AppColors.textPrimary
                              : AppColors.surfaceWhite,
                        ),
                      ),
                      child: Text(
                        context.l10n.group_invite,
                        textAlign: TextAlign.center,
                        strutStyle: context.tibetanStrutStyle(fontSize),
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          fontFamily: getSystemFontFamily(locale.languageCode),
                        ),
                      ),
                    ),
                  ),
                ],
              )
              : SizedBox(
                width: double.infinity,
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
                  style: buttonStyle.copyWith(
                    backgroundColor: WidgetStatePropertyAll(
                      isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                    ),
                    minimumSize: WidgetStatePropertyAll(
                      Size(double.infinity, buttonHeight),
                    ),
                  ),
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            isPage ? context.l10n.follow : context.l10n.join,
                            textAlign: TextAlign.center,
                            strutStyle: context.tibetanStrutStyle(fontSize),
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                              fontFamily: getSystemFontFamily(
                                locale.languageCode,
                              ),
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
    isCurrentlyFollowing
        ? await notifier.unfollow(connectGroup: profile)
        : await notifier.follow(connectGroup: profile);
  }
}
