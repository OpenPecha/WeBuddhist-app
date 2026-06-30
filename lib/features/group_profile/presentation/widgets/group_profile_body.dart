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
import 'package:intl/intl.dart';
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
  String? _enrollingSeriesId;
  final Set<String> _localGroupEnrolledSeriesIds = {};

  int get _tabCount {
    var count = 2;
    if (_hasAboutContent(widget.profile)) count++;
    return count;
  }

  int get _membersTabIndex => 1;

  bool _hasAboutContent(GroupProfile profile) {
    final hasBanner =
        profile.bannerUrl != null && profile.bannerUrl!.isNotEmpty;
    final descriptionLong = profile.descriptionLong?.trim();
    return hasBanner || (descriptionLong != null && descriptionLong.isNotEmpty);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followKey = GroupFollowKey(
      groupId: widget.profile.id,
      groupType: widget.profile.groupType,
    );
    ref.listen(groupFollowProvider(followKey), (previous, next) {
      if (next case GroupFollowSuccess(isFollowing: false)) {
        setState(_localGroupEnrolledSeriesIds.clear);
      }
    });
    ref.listen(groupProfileProvider(widget.profile.id), (previous, next) {
      next.whenData((either) {
        either.fold((_) {}, (profile) {
          final apiEnrolledIds =
              profile.series
                  .where((series) => series.isGroupEnrolled)
                  .map((series) => series.id)
                  .toSet();
          final apiNotEnrolledIds = profile.series
              .where((series) => !series.isGroupEnrolled)
              .map((series) => series.id);
          setState(() {
            _localGroupEnrolledSeriesIds.addAll(apiEnrolledIds);
            _localGroupEnrolledSeriesIds.removeAll(apiNotEnrolledIds);
          });
        });
      });
    });

    final enrollingId = _enrollingSeriesId;
    if (enrollingId != null) {
      // Keep the autoDispose enrollment provider alive while the request is
      // in flight — otherwise it can be disposed before the API returns.
      ref.watch(seriesEnrollmentProvider(enrollingId));
    }

    final locale = Localizations.localeOf(context);
    final lineHeight = getLineHeight(locale.languageCode);
    final profile = _resolveProfile();
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

  GroupProfile _resolveProfile() {
    final freshProfile = ref.watch(groupProfileProvider(widget.profile.id));
    return freshProfile.maybeWhen(
      data:
          (either) => either.fold((_) => widget.profile, (profile) => profile),
      orElse: () => widget.profile,
    );
  }

  bool _isSeriesGroupEnrolled(GroupProfileSeries series) {
    return series.isGroupEnrolled ||
        _localGroupEnrolledSeriesIds.contains(series.id);
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
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == profile.series.length - 1 ? 0 : 16,
          ),
          child: _buildSeriesCard(
            profile,
            profile.series[index],
            isDark,
            lineHeight,
          ),
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
    final hasBanner =
        profile.bannerUrl != null && profile.bannerUrl!.isNotEmpty;
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
    GroupProfile profile,
    GroupProfileSeries series,
    bool isDark,
    double? lineHeight,
  ) {
    final dateRange = _formatSeriesDateRange(series);
    final subtitle = dateRange ?? series.subTitle?.trim();
    final showPracticeOverlay = !_isSeriesGroupEnrolled(series);
    final isEnrolling = _enrollingSeriesId == series.id;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;

    return Material(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnrolling ? null : () => _onSeriesCardTap(profile, series),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  series.image != null && !series.image!.isEmpty
                      ? ResponsiveCoverImage(
                        image: series.image,
                        fit: BoxFit.cover,
                      )
                      : ColoredBox(
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
                  if (showPracticeOverlay)
                    Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      alignment: Alignment.center,
                      child:
                          isEnrolling
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  context.l10n.group_practice_with_us,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: lineHeight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                        height: lineHeight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _formatSeriesDateRange(GroupProfileSeries series) {
    final startDate = series.startDate;
    final endDate = series.endDate;
    if (startDate == null || endDate == null) return null;
    final formatter = DateFormat('MMM d');
    return '${formatter.format(startDate.toLocal())} - ${formatter.format(endDate.toLocal())}';
  }

  Future<void> _onSeriesCardTap(
    GroupProfile profile,
    GroupProfileSeries series,
  ) async {
    if (_isSeriesGroupEnrolled(series)) {
      widget.onSeriesTap?.call();
      context.push('/home/series/${series.id}');
      return;
    }

    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() => _enrollingSeriesId = series.id);

    final notifier = ref.read(seriesEnrollmentProvider(series.id).notifier);
    final ok = await notifier.enroll(groupId: profile.id);

    if (!mounted) return;
    setState(() {
      _enrollingSeriesId = null;
      if (ok) _localGroupEnrolledSeriesIds.add(series.id);
    });

    if (ok) {
      final followKey = GroupFollowKey(
        groupId: profile.id,
        groupType: profile.groupType,
      );
      ref
          .read(groupFollowProvider(followKey).notifier)
          .markAutoJoinedFromPracticeEnrollment(group: profile);
      ref.invalidate(groupProfileProvider(profile.id));
      await ref.read(groupProfileProvider(profile.id).future);
      if (!mounted) return;
      await context.pushNamed(
        'edit-routine',
        extra: {'enrollSeriesId': series.id},
      );
      if (!mounted) return;
      await ref
          .read(groupFollowProvider(followKey).notifier)
          .syncJoinStatusFromServer(connectGroup: profile);
      ref.invalidate(groupProfileProvider(profile.id));
      return;
    }

    final state = ref.read(seriesEnrollmentProvider(series.id));
    final message =
        state is SeriesEnrollmentFailure
            ? state.failure.message
            : 'Failed to enroll in series';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.mala_action_coming_soon),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
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
