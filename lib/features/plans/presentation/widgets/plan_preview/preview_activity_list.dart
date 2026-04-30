import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/plans.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:go_router/go_router.dart';

/// A read-only activity list for previewing plan tasks before enrollment.
/// Unlike ActivityList, this widget:
/// - Works with PlanTasksModel (non-enrolled data)
/// - Has no checkbox/completion toggle (preview only)
/// - Navigates to ReaderScreen with sourceTextId and NavigationContext
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
        final hasSourceText = _hasSourceText(task);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: _PreviewTaskItem(
            language: language,
            task: task,
            hasSourceText: hasSourceText,
            onTap: () => _handleActivityTap(context, task),
          ),
        );
      },
    );
  }

  void _handleActivityTap(BuildContext context, PlanTasksModel task) {
    final planTextItems = _buildPlanTextItems();
    if (planTextItems.isEmpty) return;
    final PlanSubtasksModel? subtaskWithText = _getSubtaskWithText(task);

    if (subtaskWithText != null) {
      final sourceTextId = subtaskWithText.sourceTextId;
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

      context.push('/reader/$sourceTextId', extra: navigationContext);
    }
  }

  /// Build list of plan text items for swipe navigation.
  /// One PlanTextItem per task with full segmentIds list.
  List<PlanTextItem> _buildPlanTextItems() {
    final items = <PlanTextItem>[];
    final sortedTasks = _sortedTasks;
    for (final task in sortedTasks) {
      if (task.subtasks.isEmpty) continue;
      final subtask = task.subtasks[0];
      if (subtask.sourceTextId != null && subtask.sourceTextId!.isNotEmpty) {
        items.add(
          PlanTextItem(
            textId: subtask.sourceTextId!,
            segmentIds: subtask.segmentIds,
            title: task.title,
          ),
        );
      }
    }
    return items;
  }

  /// Check if any subtask has a sourceTextId
  bool _hasSourceText(PlanTasksModel task) {
    return task.subtasks.any(
      (s) => s.sourceTextId != null && s.sourceTextId!.isNotEmpty,
    );
  }

  PlanSubtasksModel? _getSubtaskWithText(PlanTasksModel task) {
    for (final PlanSubtasksModel subtask in task.subtasks) {
      if (subtask.sourceTextId != null && subtask.sourceTextId!.isNotEmpty) {
        return subtask;
      }
    }
    return null;
  }

  String? _getFirstSegmentId(PlanSubtasksModel subtask) {
    final List<String>? segmentIds = subtask.segmentIds;
    if (segmentIds == null || segmentIds.isEmpty) return null;
    return segmentIds.first;
  }
}

/// Task item widget for preview mode (read-only, no checkbox)
class _PreviewTaskItem extends StatelessWidget {
  const _PreviewTaskItem({
    required this.language,
    required this.task,
    required this.hasSourceText,
    required this.onTap,
  });

  final String language;
  final PlanTasksModel task;
  final bool hasSourceText;
  final VoidCallback onTap;

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
                  task.title,
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
