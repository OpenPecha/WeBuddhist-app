import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/models/notification_nav.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:flutter_pecha/features/plans/domain/usecases/user_plans_usecases.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_item_card.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<UserPlansModel?> resolveRoutineUserPlan(
  WidgetRef ref,
  String planId, {
  String? language,
}) async {
  final contentLanguage = ref.read(contentLanguageProvider);
  final isSameLanguage =
      language == null ||
      language.toLowerCase() == contentLanguage.toLowerCase();

  if (isSameLanguage) {
    var plans = ref.read(myPlansPaginatedProvider).plans;
    var userPlan = plans.where((p) => p.id == planId).firstOrNull;

    if (userPlan == null) {
      await ref.read(myPlansPaginatedProvider.notifier).refresh();
      plans = ref.read(myPlansPaginatedProvider).plans;
      userPlan = plans.where((p) => p.id == planId).firstOrNull;
    }

    return userPlan;
  }

  final repo = ref.read(userPlansDomainRepositoryProvider);
  final result = await repo.getUserPlans(language: language);
  return result.fold(
    (_) => null,
    (response) => response.userPlans.where((p) => p.id == planId).firstOrNull,
  );
}

final _logger = AppLogger('RoutineFilledState');

class RoutineFilledState extends ConsumerStatefulWidget {
  final RoutineData routineData;
  final VoidCallback onEdit;
  final bool showTitle;

  const RoutineFilledState({
    super.key,
    required this.routineData,
    required this.onEdit,
    this.showTitle = true,
  });

  @override
  ConsumerState<RoutineFilledState> createState() => _RoutineFilledStateState();
}

class _RoutineFilledStateState extends ConsumerState<RoutineFilledState> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(pendingNotificationNavProvider, (previous, next) {
      if (next != null) {
        _handlePendingNotificationNav(next);
      }
    }, fireImmediately: true);
  }

  Future<void> _handlePendingNotificationNav(NotificationNav pendingNav) async {
    if (!mounted) return;

    final itemType = RoutineItemType.values.firstWhere(
      (e) => e.name == pendingNav.itemType,
      orElse: () => RoutineItemType.series,
    );
    if (itemType == RoutineItemType.recitation) {
      ref.read(pendingNotificationNavProvider.notifier).state = null;
      context.push(
        '/reader/${pendingNav.itemId}',
        extra: NavigationContext(source: NavigationSource.normal),
      );
      return;
    }

    final planId = pendingNav.planId ?? pendingNav.itemId;
    final routineItem = _findRoutineItem(widget.routineData, pendingNav.itemId);
    var userPlan =
        ref
            .read(myPlansPaginatedProvider)
            .plans
            .where((p) => p.id == planId)
            .firstOrNull;
    userPlan ??= await resolveRoutineUserPlan(
      ref,
      planId,
      language: routineItem?.language,
    );
    if (!mounted || userPlan == null) {
      return;
    }

    ref.read(pendingNotificationNavProvider.notifier).state = null;
    final startDate = userPlan.effectiveStartDate;
    final selectedDay = PlanUtils.dayNumberFor(
      startDate,
      DateTime.now(),
      userPlan.totalDays,
    ).clamp(1, userPlan.totalDays);
    _logger.info(
      '[ENROLL-NAV] notification open ${userPlan.id} '
      'seriesId=${pendingNav.itemId} selectedDay=$selectedDay/${userPlan.totalDays}',
    );
    context.push(
      '/practice/details',
      extra: {
        'plan': userPlan,
        'selectedDay': selectedDay,
        'startDate': startDate,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: _RoutineHeader(
              title: localizations.routine_title,
              editLabel: localizations.routine_edit,
              onEdit: widget.onEdit,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(height: 1),
          ),
        ],
        // Routine blocks
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userRoutineProvider);
              await ref.read(userRoutineProvider.future);
              await ref.read(myPlansPaginatedProvider.notifier).refresh();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12,
              ),
              itemCount: widget.routineData.blocks.length,
              itemBuilder: (context, index) {
                return _RoutineBlockSection(
                  block: widget.routineData.blocks[index],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutineHeader extends StatelessWidget {
  final String title;
  final String editLabel;
  final VoidCallback onEdit;
  final bool isDark;

  const _RoutineHeader({
    required this.title,
    required this.editLabel,
    required this.onEdit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),
        _EditLink(editLabel: editLabel, onEdit: onEdit, isDark: isDark),
      ],
    );
  }
}

class _EditLink extends StatelessWidget {
  final String editLabel;
  final VoidCallback onEdit;
  final bool isDark;

  const _EditLink({
    required this.editLabel,
    required this.onEdit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          editLabel,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _RoutineBlockSection extends ConsumerWidget {
  final RoutineBlock block;

  const _RoutineBlockSection({required this.block});

  Future<void> _onItemTap(
    BuildContext context,
    WidgetRef ref,
    RoutineItem item,
  ) async {
    switch (item.type) {
      case RoutineItemType.recitation:
        _navigateToReader(context, item.id);
      case RoutineItemType.series:
        if (!context.mounted) return;
        // Use go (not push) so the shell route is reused instead of inserting
        // a second /home page when navigating from this root-level route.
        context.goNamed('home-series-detail', pathParameters: {'id': item.id});
      case RoutineItemType.timer:
        _navigateToTimer(context, item);
    }
  }

  Future<void> _onPlanArrowTap(
    BuildContext context,
    WidgetRef ref,
    RoutineItem item,
  ) async {
    final planId = item.currentPlanId;
    if (planId == null) return;
    await _navigateToFirstPlanContent(context, ref, item, planId: planId);
  }

  void _navigateToReader(BuildContext context, String textId) {
    final navigationContext = NavigationContext(
      source: NavigationSource.routine,
    );
    context.push('/reader/$textId', extra: navigationContext);
  }

  void _navigateToTimer(BuildContext context, RoutineItem item) {
    final durationMs = item.durationMs;
    if (durationMs == null || durationMs <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.notFound)));
      return;
    }

    context.push(
      '/home/timers/active',
      extra: PresetTimer(id: item.id, name: item.title, durationMs: durationMs),
    );
  }

  Future<void> _navigateToFirstPlanContent(
    BuildContext context,
    WidgetRef ref,
    RoutineItem item, {
    required String planId,
    UserPlansModel? userPlan,
  }) async {
    userPlan ??= await resolveRoutineUserPlan(
      ref,
      planId,
      language: item.language,
    );

    if (userPlan == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.notFound)));
      }
      return;
    }

    if (!context.mounted) return;

    final startDate =
        userPlan.startDate ??
        item.startDate ??
        item.enrolledAt ??
        userPlan.startedAt;
    final daysSinceEnrollment =
        DateTime.now().difference(DateUtils.dateOnly(startDate)).inDays;
    final selectedDay = (daysSinceEnrollment + 1).clamp(1, userPlan.totalDays);
    _logger.info(
      '[ENROLL-NAV] open plan ${userPlan.id} '
      'anchor=${startDate.toIso8601String()} '
      'startDate=${userPlan.startDate?.toIso8601String()} '
      'startedAt=${userPlan.startedAt.toIso8601String()} '
      'selectedDay=$selectedDay/${userPlan.totalDays}',
    );

    final dayContentResult = await ref
        .read(getUserPlanDayContentUseCaseProvider)
        .call(
          PlanDayContentParams(
            planId: userPlan.id,
            dayNumber: selectedDay,
          ),
        );

    final dayData = dayContentResult.fold((_) => null, (data) => data);
    if (dayData == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.notFound)));
      }
      return;
    }

    final planTextItems = PlanSubtaskNavigation.fromUserTasks(dayData.tasks);
    if (planTextItems.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.notFound)));
      }
      return;
    }

    final targetIndex =
        planTextItems.indexWhere((planItem) => !planItem.isCompleted);
    final index = targetIndex >= 0 ? targetIndex : 0;
    final target = planTextItems[index];

    final navigationContext = NavigationContext(
      source: NavigationSource.plan,
      planId: userPlan.id,
      dayNumber: selectedDay,
      targetSegmentId: target.firstSegmentId,
      planTextItems: planTextItems,
      currentTextIndex: index,
      dayAudioUrl: dayData.audioUrl,
    );

    if (!context.mounted) return;

    PlanNavigator.push(context, target, navigationContext);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          block.formattedTime,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < block.items.length; i++) ...[
          _buildItemCard(context, ref, block.items[i]),
          if (i < block.items.length - 1) const Divider(height: 1, indent: 80),
        ],
        if (block.items.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Divider(height: 1),
          ),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, WidgetRef ref, RoutineItem item) {
    return RoutineItemCard(
      title: item.title,
      coverImage: item.coverImage,
      type: item.type,
      planTitle: item.currentPlanTitle,
      onTap: () => _onItemTap(context, ref, item),
      onPlanTap:
          item.currentPlanId != null
              ? () => _onPlanArrowTap(context, ref, item)
              : null,
    );
  }
}

RoutineItem? _findRoutineItem(RoutineData routineData, String itemId) {
  for (final block in routineData.blocks) {
    for (final item in block.items) {
      if (item.id == itemId) return item;
    }
  }
  return null;
}
