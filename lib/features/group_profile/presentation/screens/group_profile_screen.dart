import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupProfileScreen extends ConsumerWidget {
  final String groupId;

  const GroupProfileScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(groupProfileProvider(groupId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: profileAsync.when(
                data: (either) {
                  return either.fold(
                    (failure) => Center(
                      child: ErrorStateWidget(
                        error: failure,
                        onRetry:
                            () => ref.invalidate(groupProfileProvider(groupId)),
                      ),
                    ),
                    (profile) =>
                        _GroupProfileBody(profile: profile, isDark: isDark),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => Center(
                      child: ErrorStateWidget(
                        error: error,
                        onRetry:
                            () => ref.invalidate(groupProfileProvider(groupId)),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }
}

class _GroupProfileBody extends ConsumerStatefulWidget {
  final GroupProfile profile;
  final bool isDark;

  const _GroupProfileBody({required this.profile, required this.isDark});

  @override
  ConsumerState<_GroupProfileBody> createState() => _GroupProfileBodyState();
}

class _GroupProfileBodyState extends ConsumerState<_GroupProfileBody> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final lineHeight = getLineHeight(locale.languageCode);
    final profile = widget.profile;
    final isDark = widget.isDark;

    final websiteLink =
        profile.socialLinks
            .where((l) => l.platform.toLowerCase() == 'website')
            .toList();
    final socialIcons =
        profile.socialLinks
            .where((l) => l.platform.toLowerCase() != 'website')
            .toList();

    return SingleChildScrollView(
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
          if (websiteLink.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildWebsiteLink(websiteLink.first, isDark),
          ],
          if (socialIcons.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSocialIcons(socialIcons, isDark),
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
                      PhosphorIconsRegular.usersThree,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCrossFade(
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 120,
                  child: ClipRect(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: PlanInlineMarkdownView(
                        content: description,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isDescriptionExpanded = true),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'more',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlanInlineMarkdownView(content: description, fontSize: 14),
                GestureDetector(
                  onTap: () => setState(() => _isDescriptionExpanded = false),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'less',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            crossFadeState:
                _isDescriptionExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildWebsiteLink(GroupProfileSocialLink link, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: () => _launchUrl(link.url),
        child: Row(
          children: [
            Icon(PhosphorIconsRegular.link, size: 18, color: AppColors.info),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                link.url,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.info,
                  decoration: TextDecoration.underline,
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

  Widget _buildSocialIcons(List<GroupProfileSocialLink> links, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children:
            links.map((link) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => _launchUrl(link.url),
                  child: Icon(
                    _socialIcon(link.platform),
                    size: 22,
                    color: isDark ? AppColors.grey300 : AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
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
                    isFollowing ? 'Following' : 'Follow',
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
            'PRACTICES',
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
      onTap: () => context.push('/home/series/${series.id}'),
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
                            PhosphorIconsRegular.bookOpenText,
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
                  if (series.description != null &&
                      series.description!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        series.description!,
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

  IconData _socialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return PhosphorIconsRegular.instagramLogo;
      case 'facebook':
        return PhosphorIconsRegular.facebookLogo;
      case 'twitter':
      case 'x':
        return PhosphorIconsRegular.xLogo;
      case 'youtube':
        return PhosphorIconsRegular.youtubeLogo;
      case 'tiktok':
        return PhosphorIconsRegular.tiktokLogo;
      case 'linkedin':
        return PhosphorIconsRegular.linkedinLogo;
      default:
        return PhosphorIconsRegular.link;
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
