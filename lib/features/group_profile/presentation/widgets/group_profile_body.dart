import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_links_drawer.dart';
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

class _GroupProfileBodyState extends ConsumerState<GroupProfileBody> {
  bool _isDescriptionExpanded = false;

  GroupProfile _resolveProfile() {
    final refreshed = ref.watch(groupProfileProvider(widget.profile.id));
    return refreshed.maybeWhen(
      data: (either) => either.fold((_) => widget.profile, (profile) => profile),
      orElse: () => widget.profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final lineHeight = getLineHeight(locale.languageCode);
    final profile = _resolveProfile();
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
                  child: Image.network(
                    profile.bannerUrl!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
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
          _buildFollowButton(isDark),
          if (profile.series.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildPracticesSection(profile.series, isDark, lineHeight),
          ],
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
    final locale = Localizations.localeOf(context);
    final formattedJoinerCount = NumberFormat.decimalPattern(
      locale.toString(),
    ).format(profile.joinerCount);
    final memberLabel =
        profile.joinerCount == 1
            ? context.l10n.group_member
            : context.l10n.group_members;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            backgroundImage:
                profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
            child:
                (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                    ? Icon(
                      AppAssets.usersThree,
                      size: 22,
                      color: isDark ? AppColors.grey500 : AppColors.grey600,
                    )
                    : null,
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
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                      height: lineHeight,
                    ),
                    children: [
                      TextSpan(
                        text: formattedJoinerCount,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' $memberLabel'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
            Icon(
              AppAssets.linkSimple,
              size: 18,
              color: secondaryColor,
            ),
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

  Widget _buildFollowButton(bool isDark) {
    final groupId = widget.profile.id;
    final followState = ref.watch(groupFollowProvider(groupId));

    final isFollowing = switch (followState) {
      GroupFollowSuccess(isFollowing: final f) => f,
      _ => false,
    };
    final isLoading = followState is GroupFollowLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed:
              isLoading ? null : () => _onFollowPressed(groupId, isFollowing),
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
                    isFollowing ? context.l10n.joined : context.l10n.join,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
    );
  }

  void _onFollowPressed(String groupId, bool isCurrentlyFollowing) {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final notifier = ref.read(groupFollowProvider(groupId).notifier);
    if (isCurrentlyFollowing) {
      notifier.unfollow();
    } else {
      notifier.follow();
    }
  }

  Widget _buildPracticesSection(
    List<GroupProfileSeries> seriesList,
    bool isDark,
    double? lineHeight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            context.l10n.nav_practice,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textTertiaryDark : AppColors.grey800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...seriesList.map(
          (series) => _buildSeriesRow(series, isDark, lineHeight),
        ),
      ],
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
