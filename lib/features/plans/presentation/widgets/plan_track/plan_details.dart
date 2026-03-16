import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/plans/data/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../day_completion_bottom_sheet.dart';
import '../plan_cover_image.dart';
import '../day_carousel.dart';
import 'activity_list.dart';

final _logger = AppLogger('PlanDetails');

class PlanDetails extends ConsumerStatefulWidget {
  const PlanDetails({
    super.key,
    required this.plan,
    required this.selectedDay,
    required this.startDate,
  });
  final UserPlansModel plan;
  final int selectedDay;
  final DateTime startDate;

  @override
  ConsumerState<PlanDetails> createState() => _PlanDetailsState();
}

class _PlanDetailsState extends ConsumerState<PlanDetails> {
  late int selectedDay;
  final Set<String> _togglingTaskIds = {};
  final Map<int, bool> _dayCompletionTracker = {};

  @override
  void initState() {
    super.initState();
    selectedDay = widget.selectedDay;
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.plan.language;
    final localizations = context.l10n;

    _listenForDayCompletion();

    return Scaffold(
      appBar: _buildAppBar(context, language, localizations),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlanCoverImage(imageUrl: widget.plan.imageUrl ?? ''),
                  _buildDayCarouselSection(language),
                  _buildDayContentSection(context, language),
                ],
              ),
            ),
          ),
          _buildStartReadingButton(context, localizations),
        ],
      ),
    );
  }

  void _listenForDayCompletion() {
    ref.listen(
      userPlanDayContentFutureProvider(
        PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
      ),
      (previous, next) {
        final dayContent = next.valueOrNull;
        if (dayContent == null) return;

        final day = dayContent.dayNumber;
        if (_dayCompletionTracker.containsKey(day)) {
          final wasCompleted = _dayCompletionTracker[day]!;
          if (!wasCompleted && dayContent.isCompleted) {
            _onDayCompleted(day);
          }
        }
        _dayCompletionTracker[day] = dayContent.isCompleted;
      },
    );
  }

  void _onReaderClosed() {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ref.invalidate(
        userPlanDayContentFutureProvider(
          PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
        ),
      );
      ref.invalidate(userPlanDaysCompletionStatusProvider(widget.plan.id));
    });
  }

  Future<void> _onDayCompleted(int dayNumber) async {
    try {
      final completionStatus = await ref.read(
        userPlanDaysCompletionStatusProvider(widget.plan.id).future,
      );
      final completedDays = completionStatus.values.where((v) => v).length;

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => DayCompletionBottomSheet(
              dayNumber: dayNumber,
              totalDays: widget.plan.totalDays,
              completedDays: completedDays,
              imageUrl: widget.plan.imageUrl,
              planTitle: widget.plan.title,
            ),
      );
    } catch (e) {
      _logger.error('Error showing day completion', e);
    }
  }

  AppBar _buildAppBar(
    BuildContext context,
    String language,
    AppLocalizations localizations,
  ) {
    return AppBar(
      title: Text(widget.plan.title, style: TextStyle(fontSize: 20)),
      elevation: 0,
    );
  }

  Widget _buildDayCarouselSection(String language) {
    final planDays = ref.watch(planDaysByPlanIdFutureProvider(widget.plan.id));

    return planDays.when(
      data: (days) {
        if (days.isEmpty) {
          return _buildEmptyDayCarouselState(context);
        }
        return _buildDayCarouselWithStatus(language, days);
      },
      loading: () => DayCarouselSkeleton(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildDayCarouselWithStatus(
    String language,
    List<PlanDaysModel> days,
  ) {
    final dayCompletionStatus = ref.watch(
      userPlanDaysCompletionStatusProvider(widget.plan.id),
    );

    return dayCompletionStatus.when(
      data:
          (completionStatus) =>
              _buildDayCarousel(language, days, completionStatus),
      loading: () => _buildDayCarousel(language, days, null),
      error: (error, stackTrace) => _buildDayCarousel(language, days, null),
    );
  }

  Widget _buildDayCarousel(
    String language,
    List<PlanDaysModel> days,
    Map<int, bool>? completionStatus,
  ) {
    return DayCarousel(
      language: language,
      days: days,
      selectedDay: selectedDay,
      startDate: widget.startDate,
      dayCompletionStatus: completionStatus,
      onDaySelected: (day) {
        setState(() {
          selectedDay = day;
        });
      },
    );
  }

  Widget _buildDayContentSection(BuildContext context, String language) {
    final userPlanDayContent = ref.watch(
      userPlanDayContentFutureProvider(
        PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayTitle(context, language, selectedDay),
          userPlanDayContent.when(
            data:
                (dayContent) => ActivityList(
                  language: language,
                  tasks: dayContent.tasks,
                  today: selectedDay,
                  totalDays: dayContent.tasks.length,
                  planId: widget.plan.id,
                  dayNumber: selectedDay,
                  onActivityToggled:
                      (taskId) => _handleTaskToggle(taskId, dayContent.tasks),
                  onReaderClosed: _onReaderClosed,
                ),
            loading: () => const DayContentSkeleton(),
            error: (error, stackTrace) => _buildDayContentError(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayContentError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unable to load tasks',
          style: TextStyle(color: Colors.red[600]),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            ref.invalidate(userPlanDayContentFutureProvider);
          },
          child: Text(context.l10n.retry),
        ),
      ],
    );
  }

  Widget _buildEmptyDayCarouselState(BuildContext context) {
    final localizations = context.l10n;
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(child: Text(localizations.no_days_available)),
    );
  }

  Widget _buildDayTitle(BuildContext context, String language, int day) {
    return Text(
      "Day $day of ${widget.plan.totalDays}",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: "Inter",
      ),
    );
  }

  Future<void> _handleTaskToggle(
    String taskId,
    List<UserTasksDto> tasks,
  ) async {
    // Prevent race condition: Check if task is already being toggled
    if (_togglingTaskIds.contains(taskId)) {
      return;
    }

    // Safely find the task - return early if not found or list is empty
    if (tasks.isEmpty) {
      _showErrorSnackbar(context.l10n.noTasks);
      return;
    }

    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) {
      _showErrorSnackbar(context.l10n.taskNotFound);
      return;
    }

    final task = tasks[taskIndex];

    // Mark task as being toggled
    setState(() {
      _togglingTaskIds.add(taskId);
    });

    try {
      bool success;
      if (task.isCompleted) {
        success = await ref.read(deleteTaskFutureProvider(taskId).future);
      } else {
        success = await ref.read(completeTaskFutureProvider(taskId).future);
      }

      if (success && mounted) {
        ref.invalidate(
          userPlanDayContentFutureProvider(
            PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
          ),
        );
        // Also invalidate completion status to refresh checkmarks
        ref.invalidate(userPlanDaysCompletionStatusProvider(widget.plan.id));
      } else if (!success && mounted) {
        _showErrorSnackbar(context.l10n.updateTaskError);
      }
    } catch (e) {
      _logger.error('Error toggling task', e);
      if (mounted) {
        _showErrorSnackbar(context.l10n.errorDetail(e.toString()));
      }
    } finally {
      // Always remove task from toggling set
      if (mounted) {
        setState(() {
          _togglingTaskIds.remove(taskId);
        });
      }
    }
  }

  void _showUnenrollDialog(BuildContext context) {
    final localizations = context.l10n;
    final locale = ref.watch(localeProvider);
    final language = locale.languageCode;
    final fontSize = language == 'bo' || language == 'BO' ? 16.0 : 14.0;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(localizations.plan_unenroll),
          content: Text(
            language == 'bo' || language == 'BO'
                ? '${widget.plan.title} ${localizations.unenroll_confirmation}\n\n ${localizations.unenroll_message}'
                : '${localizations.unenroll_confirmation} "${widget.plan.title}"?\n\n ${localizations.unenroll_message}',
            style: TextStyle(fontSize: fontSize),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                localizations.cancel,
                style: TextStyle(fontSize: fontSize),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleUnenroll();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(
                localizations.plan_unenroll,
                style: TextStyle(fontSize: fontSize),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleUnenroll() async {
    try {
      final success = await ref.read(
        userPlanUnsubscribeFutureProvider(widget.plan.id).future,
      );

      if (success) {
        // Invalidate plans to refresh the list
        ref.invalidate(myPlansPaginatedProvider);
        ref.invalidate(findPlansPaginatedProvider);
        ref.invalidate(userPlansFutureProvider);

        if (mounted) {
          // Pop back to plans list
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.unenrollSuccess(widget.plan.title),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorSnackbar(context.l10n.unenrollError);
        }
      }
    } catch (e) {
      _logger.error('Error unenrolling from plan', e);
      if (mounted) {
        _showErrorSnackbar(context.l10n.unenrollGenericError);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  List<PlanTextItem> _buildPlanTextItems(List<UserTasksDto> tasks) {
    final items = <PlanTextItem>[];
    for (final task in tasks) {
      if (task.subTasks.isEmpty) continue;
      final subtask = task.subTasks[0];
      if (subtask.sourceTextId != null && subtask.sourceTextId!.isNotEmpty) {
        items.add(
          PlanTextItem(
            textId: subtask.sourceTextId!,
            segmentId: subtask.segmentId,
            title: task.title,
            subtaskId: subtask.id,
            isCompleted: subtask.isCompleted,
          ),
        );
      }
    }
    return items;
  }

  void _startReading(List<UserTasksDto> tasks) {
    final planTextItems = _buildPlanTextItems(tasks);
    if (planTextItems.isEmpty) return;

    // Find first uncompleted task with source text; fall back to first item
    final targetIndex = planTextItems.indexWhere((item) => !item.isCompleted);
    final index = targetIndex >= 0 ? targetIndex : 0;
    final target = planTextItems[index];

    final navigationContext = NavigationContext(
      source: NavigationSource.plan,
      planId: widget.plan.id,
      dayNumber: selectedDay,
      targetSegmentId: target.segmentId,
      planTextItems: planTextItems,
      currentTextIndex: index,
    );

    context.push('/reader/${target.textId}', extra: navigationContext).then((
      _,
    ) {
      _onReaderClosed();
    });
  }

  Widget _buildStartReadingButton(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final dayContent = ref.watch(
      userPlanDayContentFutureProvider(
        PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
      ),
    );

    final tasks = dayContent.valueOrNull?.tasks;
    final hasReadableContent =
        tasks != null &&
        tasks.any(
          (t) => t.subTasks.any(
            (s) => s.sourceTextId != null && s.sourceTextId!.isNotEmpty,
          ),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: hasReadableContent ? () => _startReading(tasks) : null,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onSurface,
              foregroundColor: Theme.of(context).colorScheme.surface,
              disabledBackgroundColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              localizations.start_reading,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
