import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/notifications/data/models/notification_nav.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_item_card.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RoutineFilledState extends ConsumerWidget {
  final RoutineData routineData;
  final VoidCallback onEdit;

  const RoutineFilledState({
    super.key,
    required this.routineData,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('EEE, MMM d').format(DateTime.now());

    // Handle deep-link from notification tap.
    final pendingNav = ref.watch(pendingNotificationNavProvider);
    final myPlansState = ref.watch(myPlansPaginatedProvider);
    if (pendingNav != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final itemType = RoutineItemType.values.firstWhere(
          (e) => e.name == pendingNav.itemType,
          orElse: () => RoutineItemType.plan,
        );
        if (itemType == RoutineItemType.recitation) {
          ref.read(pendingNotificationNavProvider.notifier).state = null;
          context.push(
            '/reader/${pendingNav.itemId}',
            extra: NavigationContext(source: NavigationSource.normal),
          );
        } else {
          final userPlan = myPlansState.plans
              .where((p) => p.id == pendingNav.itemId)
              .firstOrNull;
          if (userPlan == null) return; // plans not loaded yet — wait for next build
          ref.read(pendingNotificationNavProvider.notifier).state = null;
          final startDate = userPlan.startedAt;
          final daysSince = DateTime.now()
              .difference(DateUtils.dateOnly(startDate))
              .inDays;
          final selectedDay = (daysSince + 1).clamp(1, userPlan.totalDays);
          context.push('/practice/details', extra: {
            'plan': userPlan,
            'selectedDay': selectedDay,
            'startDate': startDate,
          });
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Edit button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: _RoutineHeader(
            title: localizations.routine_title,
            editLabel: localizations.routine_edit,
            onEdit: onEdit,
            isDark: isDark,
          ),
        ),
        // Date
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            dateStr,
            style: TextStyle(
              fontSize: 15,
              color:
                  isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Divider(height: 1),
        ),
        // Routine blocks
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            itemCount: routineData.blocks.length,
            itemBuilder: (context, index) {
              return _RoutineBlockSection(block: routineData.blocks[index]);
            },
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
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              editLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
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
      case RoutineItemType.plan:
        await _navigateToPlanDetails(context, ref, item);
    }
  }

  void _navigateToReader(BuildContext context, String textId) {
    final navigationContext = NavigationContext(source: NavigationSource.normal);
    context.push('/reader/$textId', extra: navigationContext);
  }

  Future<void> _navigateToPlanDetails(
    BuildContext context,
    WidgetRef ref,
    RoutineItem item,
  ) async {
    final userPlan = await _resolveUserPlan(ref, item.id);

    if (userPlan == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.notFound)),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final startDate = item.enrolledAt ?? userPlan.startedAt;
    final daysSinceEnrollment =
        DateTime.now().difference(DateUtils.dateOnly(startDate)).inDays;
    final selectedDay = (daysSinceEnrollment + 1).clamp(1, userPlan.totalDays);

    context.push(
      '/practice/details',
      extra: {
        'plan': userPlan,
        'selectedDay': selectedDay,
        'startDate': startDate,
      },
    );
  }

  /// Resolves the user plan from cached state, with a fallback refresh.
  Future<dynamic> _resolveUserPlan(WidgetRef ref, String planId) async {
    var plans = ref.read(myPlansPaginatedProvider).plans;
    var userPlan = plans.where((p) => p.id == planId).firstOrNull;

    // Safety net: refresh if plan not found (handles edge cases like
    // enrollment via different flow or stale cache)
    if (userPlan == null) {
      await ref.read(myPlansPaginatedProvider.notifier).refresh();
      plans = ref.read(myPlansPaginatedProvider).plans;
      userPlan = plans.where((p) => p.id == planId).firstOrNull;
    }

    return userPlan;
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
          RoutineItemCard(
            title: block.items[i].title,
            imageUrl: block.items[i].imageUrl,
            type: block.items[i].type,
            onTap: () => _onItemTap(context, ref, block.items[i]),
          ),
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
}
