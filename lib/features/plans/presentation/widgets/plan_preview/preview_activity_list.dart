import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/shared/extensions/typography_extensions.dart';
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

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
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
    // Build plan text items for swipe navigation
    final planTextItems = _buildPlanTextItems();
    if (planTextItems.isEmpty) return;

    // Find current task index
    final taskIndex = tasks.indexOf(task);
    final currentTextIndex = planTextItems.indexWhere(
      (item) => tasks.any(
        (t) =>
            t.subtasks.any((s) => s.sourceTextId == item.textId) &&
            tasks.indexOf(t) == taskIndex,
      ),
    );

    // Get sourceTextId from the first subtask that has it
    final subtaskWithText = task.subtasks.cast<dynamic>().firstWhere(
      (s) => s.sourceTextId != null && s.sourceTextId!.isNotEmpty,
      orElse: () => null,
    );

    if (subtaskWithText != null) {
      final sourceTextId = subtaskWithText.sourceTextId as String;
      final segmentId = subtaskWithText.segmentId as String?;

      // Create navigation context for plan navigation
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

  /// Build list of plan text items for swipe navigation
  List<PlanTextItem> _buildPlanTextItems() {
    final items = <PlanTextItem>[];
    for (final task in tasks) {
      // for (final subtask in task.subtasks) { - we are using the first subtask for now
      final subtask = task.subtasks[0];
      if (subtask.sourceTextId != null && subtask.sourceTextId!.isNotEmpty) {
        items.add(
          PlanTextItem(
            textId: subtask.sourceTextId!,
            segmentId: subtask.segmentId,
            title: task.title,
          ),
        );
      }
      // }
    }
    return items;
  }

  /// Check if any subtask has a sourceTextId
  bool _hasSourceText(PlanTasksModel task) {
    return task.subtasks.any(
      (s) => s.sourceTextId != null && s.sourceTextId!.isNotEmpty,
    );
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
                  style: context.languageTextStyle(
                    language,
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
