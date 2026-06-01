import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
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

  const PlanListView({super.key, required this.plans, this.seriesId});

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
            child: FeaturedPlanCard(plan: sorted.first, seriesId: seriesId),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => PlanListItem(plan: sorted[index + 1]),
              childCount: sorted.length - 1,
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

  const FeaturedPlanCard({super.key, required this.plan, this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final lineHeight = getLineHeight(locale.languageCode);
    final titleFontSize = locale.languageCode == 'bo' ? 22.0 : 18.0;
    final subtitleFontSize = locale.languageCode == 'bo' ? 18.0 : 14.0;

    final myPlansState = ref.watch(myPlansPaginatedProvider);
    final isGuest = ref.watch(authProvider).isGuest;
    final isEnrolled = !isGuest && _isPlanEnrolled(ref, plan.id);
    final enrolledInfo = isEnrolled ? _getEnrolledInfo(ref, plan.id) : null;
    final isEnrolledInfoPending =
        isEnrolled && enrolledInfo == null && myPlansState.isLoading;
    final hasDescription = plan.description.trim().isNotEmpty;

    final enrollmentState =
        seriesId != null
            ? ref.watch(seriesEnrollmentProvider(seriesId!))
            : null;
    final isEnrolling = enrollmentState is SeriesEnrollmentLoading;

    // Series-level enrolled check: true when the current screen represents a
    // series and the user is already enrolled in it. Empty set for guests.
    final isSeriesEnrolled =
        seriesId != null &&
        (ref
                .watch(userSeriesEnrollmentsProvider)
                .valueOrNull
                ?.contains(seriesId!) ??
            false);
    final hideEnrollButton = isEnrolled || isSeriesEnrolled;

    return InkWell(
      onTap:
          isEnrolledInfoPending
              ? null
              : () => _navigateToPlan(context, plan, enrolledInfo),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: PlanCoverImage(
                imageUrl: plan.coverImageUrl,
                placeholderIconSize: 48,
                placeholderAlphaMin: 0.4,
                placeholderAlphaMax: 0.7,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      height: lineHeight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasDescription) ...[
                    const SizedBox(height: 6),
                    Text(
                      plan.description,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        height: lineHeight,
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
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.black26,
                          disabledForegroundColor: Colors.white70,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:
                            isEnrolling
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
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

    // Defensive no-op: a stale render could allow a tap after the user is
    // already enrolled. Honor that latest state rather than re-POSTing.
    final alreadyEnrolled =
        ref.read(userSeriesEnrollmentsProvider).valueOrNull?.contains(id) ??
        false;
    if (alreadyEnrolled) return;

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
}

class PlanListItem extends ConsumerWidget {
  final Plan plan;

  const PlanListItem({super.key, required this.plan});

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap:
            isEnrolledInfoPending
                ? null
                : () => _navigateToPlan(context, plan, enrolledInfo),
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
              child: PlanCoverImage(
                imageUrl: plan.coverImageUrl,
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
                      if (canShowStatus)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: EnrolledPlanStatusIndicator(
                            planId: plan.id,
                            dateRange: dateRange,
                            userJoinDate: userPlan.startedAt,
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

class PlanCoverImage extends StatelessWidget {
  final String? imageUrl;
  final double placeholderIconSize;
  final double placeholderAlphaMin;
  final double placeholderAlphaMax;

  const PlanCoverImage({
    super.key,
    required this.imageUrl,
    required this.placeholderIconSize,
    required this.placeholderAlphaMin,
    required this.placeholderAlphaMax,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImageWidget(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: _buildPlaceholder(context),
        errorWidget: _buildPlaceholder(context),
      );
    }
    return _buildPlaceholder(context);
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
      (item) => item.id == planId && item.type == RoutineItemType.plan,
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
