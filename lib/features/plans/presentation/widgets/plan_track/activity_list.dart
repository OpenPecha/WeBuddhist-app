import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/data/models/author/author_dto_model.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:flutter_pecha/features/plans/plans.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Activity list for the *enrolled* plan flow. Each row is one task; the
/// chevron on a row is enabled iff at least one of its subtasks is
/// navigable (SOURCE_REFERENCE with text id, or TEXT with non-blank
/// content). Tapping the row opens the appropriate screen for the task's
/// first navigable subtask, with a unified [PlanTextItem] list so the
/// bottom-bar progress reads "1 of N", "2 of N", ... across all tasks
/// regardless of content type.
class ActivityList extends StatelessWidget {
  final String language;
  final List<UserTasksDto> tasks;
  final int today;
  final int totalDays;
  final Function(String taskId) onActivityToggled;
  final VoidCallback? onReaderClosed;
  final AuthorDtoModel? author;
  final String? planId;
  final int? dayNumber;

  const ActivityList({
    super.key,
    required this.language,
    required this.tasks,
    required this.today,
    required this.totalDays,
    required this.onActivityToggled,
    this.onReaderClosed,
    this.author,
    this.planId,
    this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    final sortedTasks = List<UserTasksDto>.from(tasks)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        final isNavigable = PlanSubtaskNavigation.isUserTaskNavigable(task);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              _TaskCheckbox(
                isCompleted: task.isCompleted,
                onTap: () => onActivityToggled(task.id),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TaskTitleButton(
                  language: language,
                  title: task.title,
                  hasNavigableContent: isNavigable,
                  onTap: () => _handleActivityTap(context, task),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleActivityTap(BuildContext context, UserTasksDto task) {
    final planTextItems = PlanSubtaskNavigation.fromUserTasks(tasks);
    if (planTextItems.isEmpty) return;

    // Tapping a row should open *that* task. Find its position in the
    // unified list (one item per task that has a navigable subtask).
    final index = planTextItems.indexWhere(
      (item) => item.subtaskId != null &&
          task.subTasks.any((s) => s.id == item.subtaskId),
    );
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

    PlanNavigator.push(context, target, navigationContext)
        .then((_) => onReaderClosed?.call());
  }
}

/// Checkbox widget for task completion with ripple effect
class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({required this.isCompleted, required this.onTap});

  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 24,
          height: 24,
          decoration: isCompleted
              ? null
              : BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).iconTheme.color!,
                    width: 1,
                  ),
                  color: Colors.transparent,
                ),
          child: isCompleted ? Icon(PhosphorIconsBold.check, size: 20) : null,
        ),
      ),
    );
  }
}

/// Task title button with ripple effect
class _TaskTitleButton extends StatelessWidget {
  const _TaskTitleButton({
    required this.title,
    required this.onTap,
    required this.language,
    required this.hasNavigableContent,
  });

  final String title;
  final VoidCallback onTap;
  final String language;
  final bool hasNavigableContent;

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
                  title,
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
