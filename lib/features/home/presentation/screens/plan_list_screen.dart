import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/home/presentation/providers/plans_by_tag_provider.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            // Back button
            _buildAppBar(context, tag),
            // Main content
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

  Widget _buildAppBar(BuildContext context, String tag) {
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
          // Invisible placeholder to balance back button and keep title centered
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
        // Featured/Banner Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _FeaturedPlanCard(plan: plans.first),
          ),
        ),
        // Spacing
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        // Plan list
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final plan = plans[index + 1];
              return _PlanListItem(plan: plan);
            }, childCount: plans.length - 1),
          ),
        ),
        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/// Featured/Banner card at the top
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

    return InkWell(
      onTap: () => _handleTap(context, ref, enrolledInfo),
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
            _buildBackgroundImage(context),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    _EnrolledPlanInfo? enrolledInfo,
  ) {
    if (enrolledInfo != null) {
      context.push('/practice/details', extra: {
        'plan': enrolledInfo.userPlan,
        'selectedDay': enrolledInfo.selectedDay,
        'startDate': enrolledInfo.startDate,
      });
    } else {
      context.push('/practice/plans/preview', extra: {'plan': plan});
    }
  }

  Widget _buildBackgroundImage(BuildContext context) {
    if (plan.coverImageUrl != null && plan.coverImageUrl!.isNotEmpty) {
      return Image.network(
        plan.coverImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(context);
        },
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
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// List item for each plan
class _PlanListItem extends ConsumerWidget {
  final Plan plan;

  const _PlanListItem({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final lineHeight = getLineHeight(locale.languageCode);
    final titleFontSize = locale.languageCode == 'bo' ? 18.0 : 16.0;
    final subtitleFontSize = locale.languageCode == 'bo' ? 16.0 : 14.0;

    final isGuest = ref.watch(authProvider).isGuest;
    final isEnrolled = !isGuest && _isPlanInRoutine(ref, plan.id);
    final enrolledInfo = isEnrolled ? _getEnrolledInfo(ref, plan.id) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          if (enrolledInfo != null) {
            context.push('/practice/details', extra: {
              'plan': enrolledInfo.userPlan,
              'selectedDay': enrolledInfo.selectedDay,
              'startDate': enrolledInfo.startDate,
            });
          } else {
            context.push('/practice/plans/preview', extra: {'plan': plan});
          }
        },
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
              child: _buildThumbnail(context),
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
                  const SizedBox(height: 4),
                  Text(
                    plan.description,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      height: lineHeight,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isEnrolled) ...[
              const SizedBox(width: 8),
              _EnrolledBadge(label: context.l10n.plan_enrolled),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (plan.coverImageUrl != null && plan.coverImageUrl!.isNotEmpty) {
      return Image.network(
        plan.coverImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(context);
        },
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
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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

/// Holds pre-computed navigation data for an enrolled plan.
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

/// Returns true if the plan exists in any routine block (lightweight check for
/// badge display even when [UserPlansModel] data hasn't loaded yet).
bool _isPlanInRoutine(WidgetRef ref, String planId) {
  final routineData = ref.watch(userRoutineProvider).valueOrNull;
  if (routineData == null) return false;
  return routineData.blocks.any(
    (block) => block.items.any(
      (item) => item.id == planId && item.type == RoutineItemType.plan,
    ),
  );
}

/// Returns [_EnrolledPlanInfo] if the plan is in the user's routine and has a
/// matching [UserPlansModel], or null otherwise.
_EnrolledPlanInfo? _getEnrolledInfo(WidgetRef ref, String planId) {
  final routineAsync = ref.watch(userRoutineProvider);
  final routineData = routineAsync.valueOrNull;
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

  final startDate = routineItem.enrolledAt ?? userPlan.startedAt;
  final daysSinceEnrollment =
      DateTime.now().difference(DateUtils.dateOnly(startDate)).inDays;
  final selectedDay = (daysSinceEnrollment + 1).clamp(1, userPlan.totalDays);

  return _EnrolledPlanInfo(
    userPlan: userPlan,
    selectedDay: selectedDay,
    startDate: startDate,
  );
}

/// Green pill badge with checkmark indicating a plan is already enrolled.
class _EnrolledBadge extends StatelessWidget {
  final String label;
  const _EnrolledBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          const SizedBox(width: 4),
          const Icon(Icons.check, color: Colors.white, size: 14),
        ],
      ),
    );
  }
}
