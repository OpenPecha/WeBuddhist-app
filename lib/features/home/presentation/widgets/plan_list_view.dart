import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/enrolled_plan_status_indicator.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_track/plan_date_range_label.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_item_chip.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Renders a non-empty list of [Plan]s as a featured card on top and a scrolling
/// list below — used by both `PlanListScreen` (tag-filtered) and
/// `SeriesDetailScreen` (series-filtered). Caller must guard against empty input.
///
/// When [seriesId] is provided, the featured card shows a series-level Enroll
/// button that enrolls the user in the whole series in one call.
class PlanListView extends StatelessWidget {
  final List<Plan> plans;
  final String? seriesId;
  final Series? series;

  const PlanListView({
    super.key,
    required this.plans,
    this.seriesId,
    this.series,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...plans]..sort((a, b) {
      if (a.displayOrder != null && b.displayOrder != null) {
        return a.displayOrder!.compareTo(b.displayOrder!);
      }
      if (a.displayOrder != null) return -1;
      if (b.displayOrder != null) return 1;
      return 0;
    });

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FeaturedPlanCard(
              plan: sorted.first,
              seriesId: seriesId,
              series: series,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  PlanListItem(plan: sorted[index], seriesId: seriesId),
              childCount: sorted.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class FeaturedPlanCard extends ConsumerWidget {
  final Plan plan;

  /// When provided, the Enroll button enrolls the user in this series
  /// (single API call covers every plan in the series). When null, the
  /// button falls back to the per-plan preview navigation.
  final String? seriesId;

  /// When provided, the card displays the series-level title, description
  /// and cover image instead of the first plan's data.
  final Series? series;

  const FeaturedPlanCard({
    super.key,
    required this.plan,
    this.seriesId,
    this.series,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final lineHeight = getLineHeight(locale.languageCode);
    final subtitleFontSize = locale.languageCode == 'bo' ? 18.0 : 14.0;

    final displayDescription = series?.subTitle ?? plan.description;
    final displayImage = series?.coverImage ?? plan.coverImage;
    final localizations = AppLocalizations.of(context)!;

    final myPlansState = ref.watch(myPlansPaginatedProvider);
    final isGuest = ref.watch(authProvider).isGuest;
    final isEnrolled = !isGuest && _isPlanEnrolled(ref, plan.id);
    final enrolledInfo = isEnrolled ? _getEnrolledInfo(ref, plan.id) : null;
    final isEnrolledInfoPending =
        isEnrolled && enrolledInfo == null && myPlansState.isLoading;
    final hasDescription = displayDescription.trim().isNotEmpty;

    final enrollmentState =
        seriesId != null
            ? ref.watch(seriesEnrollmentProvider(seriesId!))
            : null;
    final isEnrolling = enrollmentState is SeriesEnrollmentLoading;

    final seriesEnrollmentAsync =
        seriesId != null ? ref.watch(userSeriesEnrollmentsProvider) : null;
    final isSeriesEnrolled =
        seriesId != null &&
        (seriesEnrollmentAsync?.valueOrNull?.contains(seriesId!) ?? false);

    // Hide button during initial load to prevent flickering
    final isLoadingEnrollmentData =
        myPlansState.isLoading ||
        (seriesId != null && seriesEnrollmentAsync?.isLoading == true);

    final hideEnrollButton =
        isEnrolled || isSeriesEnrolled || isLoadingEnrollmentData;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enrollBackgroundColor =
        isDark ? AppColors.surfaceWhite : AppColors.scaffoldBackgroundDark;
    final enrollForegroundColor =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryDark;

    return InkWell(
      onTap: () => _navigateToSeriesInfo(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _PlanCoverImage(
                  image: displayImage,
                  placeholderIconSize: 48,
                  placeholderAlphaMin: 0.4,
                  placeholderAlphaMax: 0.7,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (series != null)
                    Text(
                      localizations.series_stats(
                        series!.plans.length,
                        series!.totalDays,
                      ),
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w500,
                        height: lineHeight,
                      ),
                    ),
                  if (hasDescription) ...[
                    if (series != null) const SizedBox(height: 6),
                    Text(
                      displayDescription,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        height: lineHeight,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (!hideEnrollButton) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (isEnrolledInfoPending || isEnrolling)
                                ? null
                                : () => _onEnrollTap(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: enrollBackgroundColor,
                          foregroundColor: enrollForegroundColor,
                          disabledBackgroundColor: enrollBackgroundColor
                              .withValues(alpha: 0.5),
                          disabledForegroundColor: enrollForegroundColor
                              .withValues(alpha: 0.5),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:
                            isEnrolling
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      enrollForegroundColor,
                                    ),
                                  ),
                                )
                                : Text(
                                  context.l10n.plan_enroll,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
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

  /// Handles a tap on the Enroll button.
  /// - Guests: opens login drawer (same guard as Add to Routine).
  /// - When [seriesId] is null: navigates to the per-plan preview screen.
  /// - When [seriesId] is set: enrolls in the series via API, then navigates
  ///   to edit-routine with the series id so all newly enrolled plans are
  ///   prefilled at the default 8:00 AM block.
  Future<void> _onEnrollTap(BuildContext context, WidgetRef ref) async {
    final isGuest = ref.read(authProvider).isGuest;
    if (isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }

    final id = seriesId;
    if (id == null) {
      _navigateToPlan(context, plan, null);
      return;
    }

    final enrollments = await ref.read(userSeriesEnrollmentsProvider.future);
    if (!context.mounted) return;
    if (enrollments.contains(id)) return;

    final notifier = ref.read(seriesEnrollmentProvider(id).notifier);
    final ok = await notifier.enroll();
    if (!context.mounted) return;

    if (ok) {
      context.pushNamed('edit-routine', extra: {'enrollSeriesId': id});
    } else {
      final state = ref.read(seriesEnrollmentProvider(id));
      final message =
          state is SeriesEnrollmentFailure
              ? state.failure.message
              : 'Failed to enroll in series';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToSeriesInfo(BuildContext context) {
    if (series == null) return;
    context.push('/home/series/${series!.id}/info', extra: {'series': series!});
  }
}

class PlanListItem extends ConsumerWidget {
  final Plan plan;
  final String? seriesId;

  const PlanListItem({super.key, required this.plan, this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final lineHeight = getLineHeight(locale.languageCode);
    final titleFontSize = locale.languageCode == 'bo' ? 18.0 : 16.0;

    final myPlansState = ref.watch(myPlansPaginatedProvider);
    final isGuest = ref.watch(authProvider).isGuest;
    final isEnrolled = !isGuest && _isPlanEnrolled(ref, plan.id);
    final enrolledInfo = isEnrolled ? _getEnrolledInfo(ref, plan.id) : null;
    final isEnrolledInfoPending =
        isEnrolled && enrolledInfo == null && myPlansState.isLoading;
    final dateRange = PlanDateRange.tryCreate(
      startDate: plan.startDate,
      totalDays: plan.totalDays,
    );
    final userPlan =
        isEnrolled ? _findUserPlan(myPlansState.plans, plan.id) : null;
    final canShowStatus = isEnrolled && userPlan != null && dateRange != null;

    final isLocked =
        plan.startDate != null && plan.startDate!.isAfter(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Opacity(
        opacity: isLocked ? 0.45 : 1.0,
        child: InkWell(
          onTap:
              (isLocked || isEnrolledInfoPending)
                  ? null
                  : () => _navigateToPlan(
                    context,
                    plan,
                    enrolledInfo,
                    seriesId: seriesId,
                  ),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                clipBehavior: Clip.antiAlias,
                child: _PlanCoverImage(
                  image: plan.coverImage,
                  placeholderIconSize: 24,
                  placeholderAlphaMin: 0.3,
                  placeholderAlphaMax: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        height: lineHeight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildDateLine(
                            context,
                            plan: plan,
                            dateRange: dateRange,
                            isEnrolled: isEnrolled,
                            lineHeight: lineHeight,
                          ),
                        ),
                        if (isLocked)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(AppAssets.lock, size: 20),
                          )
                        else if (canShowStatus)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: EnrolledPlanStatusIndicator(
                              planId: plan.id,
                              dateRange: dateRange,
                            ),
                          ),
                      ],
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

  /// Builds the left-side date display for the row.
  ///
  /// - Flexible plans without enrollment: keeps the existing "Start now" chip.
  /// - Fixed-date plans: delegates to the shared [PlanDateRangeLabel] which
  ///   picks the active black pill or the muted text variant based on whether
  ///   today falls inside the range.
  Widget _buildDateLine(
    BuildContext context, {
    required Plan plan,
    required PlanDateRange? dateRange,
    required bool isEnrolled,
    required double? lineHeight,
  }) {
    if (dateRange == null) {
      if (!isEnrolled) {
        return Align(
          alignment: Alignment.centerLeft,
          child: RoutineItemChip(label: context.l10n.start_now),
        );
      }
      return const SizedBox.shrink();
    }

    return PlanDateRangeLabel(dateRange: dateRange, lineHeight: lineHeight);
  }
}

/// Returns the [UserPlansModel] for [planId] from the user's plans list,
/// or null if the plan isn't enrolled / not yet hydrated. Pulled out so the
/// list item can share the lookup with the status indicator without doing
/// it twice.
UserPlansModel? _findUserPlan(List<UserPlansModel> plans, String planId) {
  for (final p in plans) {
    if (p.id == planId) return p;
  }
  return null;
}

class _PlanCoverImage extends StatelessWidget {
  final ResponsiveImage? image;
  final double placeholderIconSize;
  final double placeholderAlphaMin;
  final double placeholderAlphaMax;

  const _PlanCoverImage({
    required this.image,
    required this.placeholderIconSize,
    required this.placeholderAlphaMin,
    required this.placeholderAlphaMax,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCoverImage(
      image: image,
      fit: BoxFit.cover,
      placeholder: _buildPlaceholder(context),
      errorWidget: _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: placeholderAlphaMin),
            Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: placeholderAlphaMax),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: placeholderIconSize,
          color: Colors.white.withValues(alpha: 0.5),
        ),
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

void _navigateToPlan(
  BuildContext context,
  Plan plan,
  _EnrolledPlanInfo? enrolledInfo, {
  String? seriesId,
}) {
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
    context.push(
      '/practice/plans/preview',
      extra: {'plan': plan, if (seriesId != null) 'seriesId': seriesId},
    );
  }
}

/// A plan is enrolled if it appears in either the user's plans list or in
/// their routine. Either source independently is enough to mark the plan as
/// enrolled — the providers load lazily, and the user may have removed an
/// enrolled plan from their routine without unenrolling.
bool _isPlanEnrolled(WidgetRef ref, String planId) {
  final myPlansState = ref.watch(myPlansPaginatedProvider);
  if (myPlansState.plans.any((p) => p.id == planId)) return true;

  final routineData = ref.watch(userRoutineProvider).valueOrNull;
  if (routineData == null) return false;
  return routineData.blocks.any(
    (block) => block.items.any(
      (item) => item.id == planId && item.type == RoutineItemType.series,
    ),
  );
}

/// Returns the data needed to navigate to `/practice/details`.
/// The plan must be present in [myPlansPaginatedProvider]; routine membership
/// is not required (a user may be enrolled without adding the plan to a routine).
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

  final startDate = userPlan.startDate ?? userPlan.startedAt;
  final daysSinceEnrollment =
      DateTime.now().difference(DateUtils.dateOnly(startDate)).inDays;
  final selectedDay = (daysSinceEnrollment + 1).clamp(1, userPlan.totalDays);

  return _EnrolledPlanInfo(
    userPlan: userPlan,
    selectedDay: selectedDay,
    startDate: startDate,
  );
}
