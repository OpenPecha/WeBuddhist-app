import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/plan_date_range_label.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SeriesDetailScreen extends ConsumerWidget {
  final String seriesId;
  final Series? series;

  const SeriesDetailScreen({super.key, required this.seriesId, this.series});

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(seriesByIdProvider(seriesId));
    await ref.read(seriesByIdProvider(seriesId).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(myPlansPaginatedProvider);
    final seriesAsync = ref.watch(seriesByIdProvider(seriesId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: seriesAsync.when(
        data: (either) => either.fold(
          (failure) => _buildError(context, ref, failure),
          (s) => _SeriesAboutBody(
            series: s,
            onRefresh: () => _onRefresh(ref),
          ),
        ),
        loading: () => _buildLoading(context),
        error: (error, _) => _buildError(context, ref, error),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildMinimalAppBar(context, series?.title ?? ''),
          const Expanded(child: PlanListSkeleton()),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return SafeArea(
      child: Column(
        children: [
          _buildMinimalAppBar(context, series?.title ?? ''),
          Expanded(
            child: Center(
              child: ErrorStateWidget(
                error: error,
                onRetry: () => _onRefresh(ref),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalAppBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _SeriesAboutBody extends ConsumerWidget {
  const _SeriesAboutBody({required this.series, required this.onRefresh});

  final Series series;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrolledIds =
        ref.watch(userSeriesEnrollmentsProvider).valueOrNull ?? const <String>{};
    final isEnrolled = enrolledIds.contains(series.id);
    final enrollmentState = ref.watch(seriesEnrollmentProvider(series.id));
    final isEnrolling = enrollmentState is SeriesEnrollmentLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enrollBgColor =
        isDark ? AppColors.scaffoldBackgroundLight : AppColors.scaffoldBackgroundDark;
    final enrollFgColor =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryDark;

    final sorted = [...series.plans]..sort((a, b) {
      if (a.displayOrder != null && b.displayOrder != null) {
        return a.displayOrder!.compareTo(b.displayOrder!);
      }
      if (a.displayOrder != null) return -1;
      if (b.displayOrder != null) return 1;
      return 0;
    });

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Custom app bar with hero image ────────────────────────
              _HeroAppBar(
                series: series,
                isEnrolled: isEnrolled,
                onUnenrollTap: () => _showUnenrollSheet(context, ref, sorted),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Series title ──────────────────────────────────
                      Text(
                        series.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),

                      // ── Creator · plans · days ────────────────────────
                      _SeriesMetaLine(series: sorted),
                      const SizedBox(height: 20),

                      // ── About section ─────────────────────────────────
                      if (series.description.trim().isNotEmpty) ...[
                        _SectionLabel(label: 'About'),
                        const SizedBox(height: 8),
                        Text(
                          series.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),

              // ── About the creator ─────────────────────────────────────
              if (sorted.isNotEmpty && sorted.first.authorName != null)
                SliverToBoxAdapter(
                  child: _AboutCreatorSection(plan: sorted.first),
                ),

              // ── Included plans ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: context.l10n.home_series_included_plans),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _SeriesPlanRow(
                      plan: sorted[index],
                      planIndex: index,
                      totalPlans: sorted.length,
                      seriesIsEnrolled: isEnrolled,
                    ),
                    childCount: sorted.length,
                  ),
                ),
              ),

              // ── Bottom padding (+ space for sticky button) ────────────
              SliverToBoxAdapter(
                child: SizedBox(height: isEnrolled ? 24 : 100),
              ),
            ],
          ),
        ),

        // ── Sticky enroll button ──────────────────────────────────────────
        if (!isEnrolled)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _StickyEnrollButton(
              seriesId: series.id,
              isEnrolling: isEnrolling,
              enrollBgColor: enrollBgColor,
              enrollFgColor: enrollFgColor,
            ),
          ),
      ],
    );
  }

  void _showUnenrollSheet(
    BuildContext context,
    WidgetRef ref,
    List<Plan> plans,
  ) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.exit_to_app,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  l10n.plan_unenroll,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showUnenrollConfirmation(context, ref, plans);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showUnenrollConfirmation(
    BuildContext context,
    WidgetRef ref,
    List<Plan> plans,
  ) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.series_unenroll_title),
          content: Text(l10n.series_unenroll_body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _handleUnenroll(context, ref, plans);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.plan_unenroll),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleUnenroll(
    BuildContext context,
    WidgetRef ref,
    List<Plan> plans,
  ) async {
    bool anyError = false;
    for (final plan in plans) {
      final result = await ref.read(
        userPlanUnsubscribeFutureProvider(plan.id).future,
      );
      result.fold((_) => anyError = true, (_) {});
    }

    ref.invalidate(userSeriesEnrollmentsProvider);
    ref.invalidate(myPlansPaginatedProvider);
    ref.invalidate(userPlansFutureProvider);

    if (context.mounted) {
      if (anyError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.unenrollError)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.unenrollSuccess(series.title)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero app bar with cover image
// ─────────────────────────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({
    required this.series,
    required this.isEnrolled,
    this.onUnenrollTap,
  });

  final Series series;
  final bool isEnrolled;
  final VoidCallback? onUnenrollTap;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImageWidget(
              imageUrl: series.imageUrl,
              fallbackAsset: 'assets/images/tag_cover/cover_image.jpg',
              fit: BoxFit.cover,
              placeholder: _buildPlaceholder(context),
              errorWidget: _buildPlaceholder(context),
            ),
          ),
          // Gradient overlay for legible back button
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),
          // Back button + optional 3-dot menu
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ImageNavButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  if (isEnrolled && onUnenrollTap != null)
                    _ImageNavButton(
                      icon: Icons.more_horiz,
                      onTap: onUnenrollTap!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
    );
  }
}

class _ImageNavButton extends StatelessWidget {
  const _ImageNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Series metadata line (Creator · N plans · N days)
// ─────────────────────────────────────────────────────────────────────────────

class _SeriesMetaLine extends StatelessWidget {
  const _SeriesMetaLine({required this.series});

  final List<Plan> series;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    final parts = <String>[];
    final creator = series.isNotEmpty ? series.first.authorName : null;
    if (creator != null && creator.isNotEmpty) parts.add(creator);
    if (series.isNotEmpty) parts.add(l10n.home_series_n_plans(series.length));

    return Text(
      parts.join(' · '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About the creator section
// ─────────────────────────────────────────────────────────────────────────────

class _AboutCreatorSection extends StatelessWidget {
  const _AboutCreatorSection({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final creatorName = plan.authorName ?? '';
    if (creatorName.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.greyLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(label: l10n.home_series_about_creator),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author avatar placeholder
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 24,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          creatorName,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            // Navigate to creator page in a future sub-issue.
                          },
                          child: Text(
                            l10n.home_series_view_creator_page(creatorName),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, color: dividerColor),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan row within the series About page
// ─────────────────────────────────────────────────────────────────────────────

class _SeriesPlanRow extends ConsumerWidget {
  const _SeriesPlanRow({
    required this.plan,
    required this.planIndex,
    required this.totalPlans,
    required this.seriesIsEnrolled,
  });

  final Plan plan;
  final int planIndex;
  final int totalPlans;
  final bool seriesIsEnrolled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final lineHeight = getLineHeight(locale.languageCode);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    // Pre-warm so _getEnrolledInfo below sees current plan list.
    ref.watch(myPlansPaginatedProvider);
    final isGuest = ref.watch(authProvider).isGuest;
    final enrolledInfo =
        (!isGuest && seriesIsEnrolled)
            ? _getEnrolledInfo(ref, plan.id)
            : null;

    final dateRange = PlanDateRange.tryCreate(
      startDate: plan.startDate,
      totalDays: plan.totalDays,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _onTap(context, ref, enrolledInfo),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover thumbnail ───────────────────────────────────────
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).colorScheme.surfaceContainer,
              ),
              clipBehavior: Clip.antiAlias,
              child: _PlanThumbnail(imageUrl: plan.coverImageUrl),
            ),
            const SizedBox(width: 12),

            // ── Plan details ──────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan N of M label
                  Text(
                    'Plan ${planIndex + 1} of $totalPlans',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: lineHeight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (plan.totalDays > 0)
                        Text(
                          context.l10n.home_series_n_days(plan.totalDays),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: subtitleColor),
                        ),
                      if (dateRange != null) ...[
                        const SizedBox(width: 8),
                        PlanDateRangeLabel(
                          dateRange: dateRange,
                          lineHeight: lineHeight,
                        ),
                      ],
                    ],
                  ),
                  if (seriesIsEnrolled && enrolledInfo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _EnrolledChip(
                        dayNum: enrolledInfo.selectedDay,
                        totalDays: plan.totalDays,
                      ),
                    ),
                ],
              ),
            ),

            // ── Chevron ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(
    BuildContext context,
    WidgetRef ref,
    _EnrolledPlanInfo? enrolledInfo,
  ) {
    if (enrolledInfo != null) {
      context.push(
        '/practice/details',
        extra: {
          'plan': enrolledInfo.userPlan,
          'selectedDay': enrolledInfo.selectedDay,
          'startDate': enrolledInfo.startDate,
        },
      );
    } else {
      context.push('/practice/plans/preview', extra: {'plan': plan});
    }
  }

  _EnrolledPlanInfo? _getEnrolledInfo(WidgetRef ref, String planId) {
    final myPlansState = ref.watch(myPlansPaginatedProvider);
    UserPlansModel? userPlan;
    for (final p in myPlansState.plans) {
      if (p.id == planId) {
        userPlan = p;
        break;
      }
    }
    if (userPlan == null) return null;

    final anchor = userPlan.effectiveStartDate;
    final dayNum = PlanUtils.dayNumberFor(anchor, DateTime.now(), userPlan.totalDays);
    final selectedDay = dayNum.clamp(1, userPlan.totalDays);
    return _EnrolledPlanInfo(
      userPlan: userPlan,
      selectedDay: selectedDay,
      startDate: anchor,
    );
  }
}

class _EnrolledChip extends StatelessWidget {
  const _EnrolledChip({required this.dayNum, required this.totalDays});

  final int dayNum;
  final int totalDays;

  @override
  Widget build(BuildContext context) {
    final isDone = dayNum > totalDays;
    final label =
        isDone ? 'Complete' : 'Day $dayNum of $totalDays';
    final color =
        isDone
            ? Colors.green
            : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PlanThumbnail extends StatelessWidget {
  const _PlanThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImageWidget(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: _placeholder(context),
        errorWidget: _placeholder(context),
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 24,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky enroll button
// ─────────────────────────────────────────────────────────────────────────────

class _StickyEnrollButton extends ConsumerWidget {
  const _StickyEnrollButton({
    required this.seriesId,
    required this.isEnrolling,
    required this.enrollBgColor,
    required this.enrollFgColor,
  });

  final String seriesId;
  final bool isEnrolling;
  final Color enrollBgColor;
  final Color enrollFgColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isEnrolling ? null : () => _onEnroll(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: enrollBgColor,
            foregroundColor: enrollFgColor,
            disabledBackgroundColor: enrollBgColor.withValues(alpha: 0.5),
            disabledForegroundColor: enrollFgColor.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: isEnrolling
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(enrollFgColor),
                  ),
                )
              : Text(
                  context.l10n.plan_enroll,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _onEnroll(BuildContext context, WidgetRef ref) async {
    final isGuest = ref.read(authProvider).isGuest;
    if (isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }

    final alreadyEnrolled =
        ref.read(userSeriesEnrollmentsProvider).valueOrNull?.contains(seriesId) ??
        false;
    if (alreadyEnrolled) return;

    final notifier = ref.read(seriesEnrollmentProvider(seriesId).notifier);
    final ok = await notifier.enroll();
    if (!context.mounted) return;

    if (ok) {
      context.pushNamed('edit-routine', extra: {'enrollSeriesId': seriesId});
    } else {
      final state = ref.read(seriesEnrollmentProvider(seriesId));
      final message =
          state is SeriesEnrollmentFailure
              ? state.failure.message
              : 'Failed to enroll in series';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _EnrolledPlanInfo {
  final UserPlansModel userPlan;
  final int selectedDay;
  final DateTime startDate;

  const _EnrolledPlanInfo({
    required this.userPlan,
    required this.selectedDay,
    required this.startDate,
  });
}
