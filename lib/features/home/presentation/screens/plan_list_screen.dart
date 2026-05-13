import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/home/presentation/providers/plans_by_tag_provider.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_item_chip.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PlanListScreen extends ConsumerWidget {
  final String tag;

  const PlanListScreen({super.key, required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansByTagProvider(tag));
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: plansAsync.when(
                data: (plansEither) {
                  return plansEither.fold(
                    (failure) => ErrorStateWidget(
                      error: failure,
                      onRetry: () => ref.refresh(plansByTagProvider(tag)),
                    ),
                    (plans) {
                      if (plans.isEmpty) {
                        return _buildEmptyState(context, localizations, ref);
                      }
                      return _buildContent(context, ref, plans);
                    },
                  );
                },
                loading: () => const PlanListSkeleton(),
                error:
                    (error, stackTrace) => ErrorStateWidget(
                      error: error,
                      onRetry: () => ref.refresh(plansByTagProvider(tag)),
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
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                _capitalizeTag(tag),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  String _capitalizeTag(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations localizations,
    WidgetRef ref,
  ) {
    final locale = ref.watch(localeProvider);
    final fontSize = locale.languageCode == 'bo' ? 22.0 : 18.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          localizations.no_feature_content,
          style: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<Plan> plans) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _FeaturedPlanCard(plan: plans.first),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _PlanListItem(plan: plans[index + 1]),
              childCount: plans.length - 1,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _FeaturedPlanCard extends ConsumerWidget {
  final Plan plan;

  const _FeaturedPlanCard({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final lineHeight = getLineHeight(locale.languageCode);
    final titleFontSize = locale.languageCode == 'bo' ? 22.0 : 18.0;
    final subtitleFontSize = locale.languageCode == 'bo' ? 18.0 : 14.0;

    final isGuest = ref.watch(authProvider).isGuest;
    final isEnrolled = !isGuest && _isPlanInRoutine(ref, plan.id);
    final enrolledInfo = isEnrolled ? _getEnrolledInfo(ref, plan.id) : null;
    final isFlexible = plan.startDate == null;

    return InkWell(
      onTap: () => _navigateToPlan(context, plan, enrolledInfo),
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
            _PlanCoverImage(
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
                child: _EnrolledBadge(label: context.l10n.plan_enrolled),
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
                        if (!isEnrolled) ...[
                          const SizedBox(width: 8),
                          _EnrollButton(
                            label: context.l10n.plan_enroll,
                            onTap: () => _handleEnroll(context, ref, plan),
                          ),
                        ],
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

class _PlanListItem extends ConsumerWidget {
  final Plan plan;

  const _PlanListItem({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final lineHeight = getLineHeight(locale.languageCode);
    final titleFontSize = locale.languageCode == 'bo' ? 18.0 : 16.0;

    final isGuest = ref.watch(authProvider).isGuest;
    final isEnrolled = !isGuest && _isPlanInRoutine(ref, plan.id);
    final enrolledInfo = isEnrolled ? _getEnrolledInfo(ref, plan.id) : null;
    final isFlexible = plan.startDate == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _navigateToPlan(context, plan, enrolledInfo),
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
                        _EnrolledBadge(label: context.l10n.plan_enrolled)
                      else
                        _EnrollButton(
                          label: context.l10n.plan_enroll,
                          onTap: () => _handleEnroll(context, ref, plan),
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
}

class _PlanCoverImage extends StatelessWidget {
  final String? imageUrl;
  final double placeholderIconSize;
  final double placeholderAlphaMin;
  final double placeholderAlphaMax;

  const _PlanCoverImage({
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

bool _isPlanInRoutine(WidgetRef ref, String planId) {
  final routineData = ref.watch(userRoutineProvider).valueOrNull;
  if (routineData == null) return false;
  return routineData.blocks.any(
    (block) => block.items.any(
      (item) => item.id == planId && item.type == RoutineItemType.plan,
    ),
  );
}

_EnrolledPlanInfo? _getEnrolledInfo(WidgetRef ref, String planId) {
  final routineData = ref.watch(userRoutineProvider).valueOrNull;
  if (routineData == null) return null;

  RoutineItem? routineItem;
  for (final block in routineData.blocks) {
    for (final item in block.items) {
      if (item.id == planId && item.type == RoutineItemType.plan) {
        routineItem = item;
        break;
      }
    }
    if (routineItem != null) break;
  }
  if (routineItem == null) return null;

  final myPlansState = ref.watch(myPlansPaginatedProvider);
  UserPlansModel? userPlan;
  for (final p in myPlansState.plans) {
    if (p.id == planId) {
      userPlan = p;
      break;
    }
  }
  if (userPlan == null) return null;

  final startDate =
      userPlan.startDate ?? routineItem.enrolledAt ?? userPlan.startedAt;
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

void _handleEnroll(BuildContext context, WidgetRef ref, Plan plan) {
  final isGuest = ref.read(authProvider).isGuest;
  if (isGuest) {
    LoginDrawer.show(context, ref);
    return;
  }
  context.push(AppRoutes.practicePlanPreview, extra: {'plan': plan});
}

class _EnrollButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _EnrollButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 14),
            const SizedBox(width: 4),
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
      ),
    );
  }
}

class _EnrolledBadge extends StatelessWidget {
  final String label;
  const _EnrolledBadge({required this.label});

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
