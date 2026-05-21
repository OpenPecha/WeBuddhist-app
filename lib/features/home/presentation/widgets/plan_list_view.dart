import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_item_chip.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Renders a non-empty list of [Plan]s as a featured card on top and a scrolling
/// list below — used by both `PlanListScreen` (tag-filtered) and
/// `SeriesDetailScreen` (series-filtered). Caller must guard against empty input.
class PlanListView extends StatelessWidget {
  final List<Plan> plans;

  const PlanListView({super.key, required this.plans});

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
            child: FeaturedPlanCard(plan: sorted.first),
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

  const FeaturedPlanCard({super.key, required this.plan});

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
    final isEnrolledInfoPending = isEnrolled && enrolledInfo == null && myPlansState.isLoading;
    final isFlexible = plan.startDate == null;

    return InkWell(
      onTap: isEnrolledInfoPending ? null : () => _navigateToPlan(context, plan, enrolledInfo),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PlanCoverImage(
              imageUrl: plan.coverImageUrl,
              placeholderIconSize: 48,
              placeholderAlphaMin: 0.4,
              placeholderAlphaMax: 0.7,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            if (isEnrolled)
              Positioned(
                top: 12,
                right: 12,
                child: EnrolledBadge(label: context.l10n.plan_enrolled),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    plan.title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      height: lineHeight,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 4,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.description,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      height: lineHeight,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_showFeaturedChipRow(isEnrolled, isFlexible, plan)) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        RoutineItemChip(
                          label:
                              isFlexible
                                  ? context.l10n.start_now
                                  : context.l10n.plan_starts_on(
                                    DateFormat(
                                      'MMM d',
                                    ).format(plan.startDate!.toLocal()),
                                  ),
                        ),
                      ],
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
    final isEnrolledInfoPending = isEnrolled && enrolledInfo == null && myPlansState.isLoading;
    final isFlexible = plan.startDate == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: isEnrolledInfoPending ? null : () => _navigateToPlan(context, plan, enrolledInfo),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isFlexible && !isEnrolled)
                        RoutineItemChip(label: context.l10n.start_now)
                      else if (!isFlexible &&
                          (!isEnrolled ||
                              DateTime.now().isBefore(plan.startDate!)))
                        RoutineItemChip(
                          label: context.l10n.plan_starts_on(
                            DateFormat(
                              'MMM d',
                            ).format(plan.startDate!.toLocal()),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (isEnrolled)
                        EnrolledBadge(label: context.l10n.plan_enrolled),
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
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => _buildPlaceholder(context),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(context);
        },
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

class EnrolledBadge extends StatelessWidget {
  final String label;
  const EnrolledBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

/// Returns the data needed to navigate to `/practice/details`. Requires the
/// plan to be present in [myPlansPaginatedProvider] (the canonical source for
/// `UserPlansModel`). If the plan is only known via the routine, this returns
/// null and the caller should fall back to the preview screen.
_EnrolledPlanInfo? _getEnrolledInfo(WidgetRef ref, String planId) {
  final routineData = ref.watch(userRoutineProvider).valueOrNull;
  if (routineData == null) return null;

  RoutineItem? routinePlanItem;
  for (final block in routineData.blocks) {
    for (final item in block.items) {
      if (item.id == planId && item.type == RoutineItemType.plan) {
        routinePlanItem = item;
        break;
      }
    }
    if (routinePlanItem != null) break;
  }
  if (routinePlanItem == null) return null;

  final myPlansState = ref.watch(myPlansPaginatedProvider);
  debugPrint('myPlansState:::::: $myPlansState');
  debugPrint('myPlansState.plans:::::: ${myPlansState.plans}');
  UserPlansModel? userPlan;
  for (final p in myPlansState.plans) {
    debugPrint('p:::::: $p');
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

bool _showFeaturedChipRow(bool isEnrolled, bool isFlexible, Plan plan) {
  if (!isEnrolled) return true;
  if (isFlexible) return false;
  return DateTime.now().isBefore(plan.startDate!);
}
