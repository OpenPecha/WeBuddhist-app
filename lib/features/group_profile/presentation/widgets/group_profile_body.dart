import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_links_drawer.dart';
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
  String? _enrollingSeriesId;
  final Set<String> _localGroupEnrolledSeriesIds = {};

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
                  .where((series) => series.isGroupEnrolled == true)
                  .map((series) => series.id)
                  .toSet();
          final apiNotEnrolledIds = profile.series
              .where((series) => series.isGroupEnrolled == null)
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
          if (profile.series.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildPracticesSection(profile, isDark, lineHeight),
          ],
          const SizedBox(height: 24),
          _buildAboutContent(profile),
          const SizedBox(height: 32),
        ],
      ),
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

  bool? _seriesGroupEnrollmentStatus(GroupProfileSeries series) {
    return seriesGroupEnrollmentStatus(
      series,
      localEnrolledSeriesIds: _localGroupEnrolledSeriesIds,
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

  Widget _buildPracticesSection(
    GroupProfile profile,
    bool isDark,
    double? lineHeight,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < profile.series.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == profile.series.length - 1 ? 0 : 16,
              ),
              child: _buildSeriesCard(
                profile,
                profile.series[i],
                isDark,
                lineHeight,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAboutContent(GroupProfile profile) {
    final descriptionLong = profile.descriptionLong?.trim();
    final hasBanner =
        profile.bannerUrl != null && profile.bannerUrl!.isNotEmpty;
    final hasDescription =
        descriptionLong != null && descriptionLong.isNotEmpty;

    if (!hasBanner && !hasDescription) {
      return const SizedBox.shrink();
    }

    final isDark = widget.isDark;
    final bodyFontSize = getLocalizedFontSize(AppTextSize.body);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
    final enrollmentStatus = _seriesGroupEnrollmentStatus(series);
    final showPracticeOverlay = enrollmentStatus != true;
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
        onTap:
            isEnrolling ? null : () => _navigateToSeriesDetail(profile, series),
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
                              : GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap:
                                    () => _onPracticeWithUsTap(profile, series),
                                child: Container(
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

  void _navigateToSeriesDetail(
    GroupProfile profile,
    GroupProfileSeries series,
  ) {
    if (_seriesGroupEnrollmentStatus(series) == true) {
      context.push('/home/series/${series.id}');
      return;
    }

    context.push(
      '/home/series/${series.id}',
      extra: {
        'groupId': profile.id,
        'groupType': profile.groupType,
        'isGroupEnrolled': false,
      },
    );
  }

  Future<void> _onPracticeWithUsTap(
    GroupProfile profile,
    GroupProfileSeries series,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final enrollmentStatus = _seriesGroupEnrollmentStatus(series);
    final confirmed = await confirmGroupPracticeChangeIfNeeded(
      context,
      enrollmentStatus,
    );
    if (!confirmed || !mounted) return;

    setState(() => _enrollingSeriesId = series.id);

    final ok = await enrollSeriesThroughGroup(
      ref: ref,
      seriesId: series.id,
      groupId: profile.id,
      groupType: profile.groupType,
    );

    if (!mounted) return;
    setState(() {
      _enrollingSeriesId = null;
      if (ok) _localGroupEnrolledSeriesIds.add(series.id);
    });

    if (ok) {
      await ref.read(groupProfileProvider(profile.id).future);
      if (!mounted) return;
      await context.pushNamed(
        'edit-routine',
        extra: {'enrollSeriesId': series.id},
      );
      if (!mounted) return;
      await completeGroupPracticeEnrollmentFlow(
        ref: ref,
        groupId: profile.id,
        groupType: profile.groupType,
      );
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
