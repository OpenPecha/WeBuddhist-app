import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/data/models/author/author_dto_model.dart';
import 'package:flutter_pecha/features/plans/plans.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
        final isCompleted = task.isCompleted;
        final taskId = task.id;
        final hasSourceText = _hasSourceText(task);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              _TaskCheckbox(
                isCompleted: isCompleted,
                onTap: () => onActivityToggled(taskId),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TaskTitleButton(
                  language: language,
                  title: task.title,
                  hasSourceText: hasSourceText,
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
    final planTextItems = _buildPlanTextItems();
    if (planTextItems.isEmpty) return;
    final UserSubtasksDto? subtaskWithText = _getSubtaskWithText(task);

    if (subtaskWithText != null) {
      final sourceTextId = subtaskWithText.sourceTextId as String;
      final segmentId = _getFirstSegmentId(subtaskWithText);

      final currentTextIndex = planTextItems.indexWhere(
        (item) => item.textId == sourceTextId,
      );

      final navigationContext = NavigationContext(
        source: NavigationSource.plan,
        planId: planId,
        dayNumber: dayNumber,
        targetSegmentId: segmentId,
        planTextItems: planTextItems,
        currentTextIndex: currentTextIndex >= 0 ? currentTextIndex : 0,
      );

      context.push('/reader/$sourceTextId', extra: navigationContext).then((_) {
        onReaderClosed?.call();
      });
    }
  }

  /// Build list of plan text items for swipe navigation.
  /// One PlanTextItem per task with full segmentIds list.
  List<PlanTextItem> _buildPlanTextItems() {
    final items = <PlanTextItem>[];
    for (final task in tasks) {
      if (task.subTasks.isEmpty) continue;
      final subtask = task.subTasks[0];
      if (subtask.sourceTextId != null && subtask.sourceTextId!.isNotEmpty) {
        items.add(
          PlanTextItem(
            textId: subtask.sourceTextId!,
            segmentIds: subtask.segmentIds,
            title: task.title,
            subtaskId: subtask.id,
            isCompleted: subtask.isCompleted,
          ),
        );
      }
    }
    return items;
  }

  /// Check if any subtask has a sourceTextId
  bool _hasSourceText(UserTasksDto task) {
    return task.subTasks.any(
      (s) => s.sourceTextId != null && s.sourceTextId!.isNotEmpty,
    );
  }

  UserSubtasksDto? _getSubtaskWithText(UserTasksDto task) {
    for (final UserSubtasksDto subtask in task.subTasks) {
      if (subtask.sourceTextId != null && subtask.sourceTextId!.isNotEmpty) {
        return subtask;
      }
    }
    return null;
  }

  String? _getFirstSegmentId(UserSubtasksDto subtask) {
    final List<String>? segmentIds = subtask.segmentIds;
    if (segmentIds == null || segmentIds.isEmpty) return null;
    return segmentIds.first;
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
          decoration:
              isCompleted
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
    required this.hasSourceText,
  });

  final String title;
  final VoidCallback onTap;
  final String language;
  final bool hasSourceText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasSourceText ? onTap : null,
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
              if (hasSourceText) ...[
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
