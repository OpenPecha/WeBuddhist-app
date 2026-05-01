import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:flutter_pecha/features/plans/plans.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// A read-only activity list for previewing plan tasks before enrollment.
/// Mirrors `ActivityList` but works with `PlanTasksModel` (non-enrolled
/// data) and never tracks subtask completion.
///
/// Tapping a row opens the appropriate screen (ReaderScreen for
/// SOURCE_REFERENCE, PlanTextScreen for TEXT) with the unified
/// [PlanTextItem] list, so the bottom-bar progress works the same as in
/// the enrolled flow.
class PreviewActivityList extends StatelessWidget {
  final String language;
  final List<PlanTasksModel> tasks;
  final int today;
  final int totalDays;
  final String? planId;
  final int? dayNumber;

  const PreviewActivityList({
    super.key,
    required this.language,
    required this.tasks,
    required this.today,
    required this.totalDays,
    this.planId,
    this.dayNumber,
  });

  List<PlanTasksModel> get _sortedTasks {
    return List<PlanTasksModel>.from(tasks)..sort((a, b) {
      final orderA = a.displayOrder ?? 0;
      final orderB = b.displayOrder ?? 0;
      return orderA.compareTo(orderB);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedTasks = _sortedTasks;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        final isNavigable = PlanSubtaskNavigation.isPlanTaskNavigable(task);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: _PreviewTaskItem(
            language: language,
            task: task,
            hasNavigableContent: isNavigable,
            onTap: () => _handleActivityTap(context, task),
          ),
        );
      },
    );
  }

  void _handleActivityTap(BuildContext context, PlanTasksModel task) {
    final planTextItems = PlanSubtaskNavigation.fromPlanTasks(tasks);
    if (planTextItems.isEmpty) return;

    // Find this task's position in the unified list. Without subtaskId
    // (preview mode) we match on title — task titles are unique within
    // a day in practice, and a stale match still navigates somewhere
    // reasonable in the same list.
    final index = planTextItems.indexWhere((item) => item.title == task.title);
    if (index < 0) return;

    final target = planTextItems[index];
    final navigationContext = NavigationContext(
      source: NavigationSource.plan,
      planId: planId,
      dayNumber: dayNumber,
      targetSegmentId: target.firstSegmentId,
      planTextItems: planTextItems,
      currentTextIndex: index,
    );

    PlanNavigator.push(context, target, navigationContext);
  }
}

/// Task item widget for preview mode (read-only, no checkbox)
class _PreviewTaskItem extends StatelessWidget {
  const _PreviewTaskItem({
    required this.language,
    required this.task,
    required this.hasNavigableContent,
    required this.onTap,
  });

  final String language;
  final PlanTasksModel task;
  final bool hasNavigableContent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasNavigableContent ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              if (hasNavigableContent) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: Theme.of(context).iconTheme.color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
