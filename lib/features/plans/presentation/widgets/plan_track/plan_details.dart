import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
// locale_notifier removed — localeProvider no longer used in this file
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
// routine_api_models not needed directly — TimeBlockRequest inferred via routineBlockToRequest
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_api_mapper.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_time_utils.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import '../celebration/day_celebration_modal.dart';
import '../celebration/plan_celebration_modal.dart';
import '../celebration/series_celebration_modal.dart';
import '../day_carousel.dart';
import 'activity_list.dart';
import 'missed_days_badge.dart';
import 'on_track_badge.dart';

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
    _logger.info('PlanDetails opened — id: ${widget.plan.id} | title: "${widget.plan.title}"');
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
                  _buildSeriesBreadcrumb(context),
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

  /// Looks up which series (if any) this plan belongs to and returns a
  /// breadcrumb like "FOUR NOBLE TRUTHS · PLAN 2 OF 4". Returns an empty
  /// widget when the plan is standalone.
  Widget _buildSeriesBreadcrumb(BuildContext context) {
    final seriesAsync = ref.watch(seriesListFutureProvider);
    final seriesEntry = seriesAsync.whenOrNull(
      data: (either) => either.fold((_) => null, (list) {
        for (final s in list) {
          final idx = s.plans.indexWhere((p) => p.id == widget.plan.id);
          if (idx >= 0) return (series: s, index: idx);
        }
        return null;
      }),
    );

    if (seriesEntry == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        '${seriesEntry.series.title.toUpperCase()} · PLAN ${seriesEntry.index + 1} OF ${seriesEntry.series.plans.length}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _listenForDayCompletion() {
    ref.listen(
      userPlanDayContentFutureProvider(
        PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
      ),
      (previous, next) {
        // Handle Either type
        final dayContentEither = next.valueOrNull;
        if (dayContentEither == null) return;

        dayContentEither.fold(
          (failure) {
            _logger.error('Error loading day content: ${failure.message}');
          },
          (dayContent) {
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
    if (!mounted) return;
    final isLastDay = dayNumber == widget.plan.totalDays;

    if (!isLastDay) {
      _showDailyCelebration(dayNumber);
      return;
    }

    // Last day — determine series context. Await ensures data is loaded
    // even if the user navigated here directly from the Practice tab.
    ({Series series, int planIndex})? seriesEntry;
    try {
      final seriesResult = await ref.read(seriesListFutureProvider.future);
      seriesResult.fold((_) {}, (list) {
        for (final s in list) {
          final idx = s.plans.indexWhere((p) => p.id == widget.plan.id);
          if (idx >= 0) {
            seriesEntry = (series: s, planIndex: idx);
            break;
          }
        }
      });
    } catch (_) {}

    if (seriesEntry == null) {
      // Standalone plan — plan done, no next plan.
      _showPlanCelebration(nextPlanTitle: null, onContinue: () {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }

    final series = seriesEntry!.series;
    final planIndex = seriesEntry!.planIndex;
    final isLastPlan = planIndex >= series.plans.length - 1;

    if (isLastPlan) {
      _showSeriesCelebration(series);
    } else {
      final nextPlan = series.plans[planIndex + 1];
      // Resolve the enrolled UserPlan for the next plan.
      UserPlansModel? nextUserPlan;
      try {
        final result = await ref.read(userPlansFutureProvider.future);
        result.fold((_) {}, (response) {
          final matches =
              response.userPlans.where((p) => p.id == nextPlan.id).toList();
          if (matches.isNotEmpty) nextUserPlan = matches.first;
        });
      } catch (_) {}

      if (!mounted) return;
      _showPlanCelebration(
        nextPlanTitle: nextPlan.title,
        onContinue: () {
          Navigator.of(context).pop(); // dismiss modal
          if (nextUserPlan != null) {
            final startDate =
                nextUserPlan!.startDate ?? nextUserPlan!.startedAt;
            context.push(
              '/practice/details',
              extra: {
                'plan': nextUserPlan,
                'selectedDay': 1,
                'startDate': startDate,
              },
            );
            // Refresh routine so it auto-advances to the next plan.
            ref.invalidate(userRoutineProvider);
          }
        },
      );
    }
  }

  void _showDailyCelebration(int dayNumber) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DayCelebrationModal(
        dayNumber: dayNumber,
        totalDays: widget.plan.totalDays,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showPlanCelebration({
    required String? nextPlanTitle,
    required VoidCallback onContinue,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PlanCelebrationModal(
        planTitle: widget.plan.title,
        totalDays: widget.plan.totalDays,
        nextPlanTitle: nextPlanTitle,
        onContinue: onContinue,
      ),
    );
  }

  void _showSeriesCelebration(Series series) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SeriesCelebrationModal(
        series: series,
        onFindAnotherSeries: () {
          Navigator.of(context).pop();
          // Switch to Home tab so user can discover more series.
          ref.read(mainNavigationIndexProvider.notifier).state =
              MainTab.home.index;
        },
        onStay: () => Navigator.of(context).pop(),
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    String language,
    AppLocalizations localizations,
  ) {
    return AppBar(
      title: Text(
        widget.plan.title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz),
          tooltip: 'Options',
          onPressed: () => _showOptionsSheet(context),
        ),
      ],
    );
  }

  Widget _buildDayCarouselSection(String language) {
    final planDays = ref.watch(planDaysByPlanIdFutureProvider(widget.plan.id));

    return planDays.when(
      data: (daysEither) {
        return daysEither.fold(
          (failure) {
            _logger.error('Error loading plan days: ${failure.message}');
            return _buildEmptyDayCarouselState(context);
          },
          (days) {
            if (days.isEmpty) {
              return _buildEmptyDayCarouselState(context);
            }
            return _buildDayCarouselWithStatus(language, days);
          },
        );
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
      data: (completionStatusEither) {
        return completionStatusEither.fold(
          (failure) {
            _logger.error(
              'Error loading completion status: ${failure.message}',
            );
            return _buildDayCarousel(language, days, null);
          },
          (completionStatus) {
            return _buildDayCarousel(language, days, completionStatus);
          },
        );
      },
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
    final completionStatus = ref.watch(
      userPlanDaysCompletionStatusProvider(widget.plan.id),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayTitle(
            context,
            language,
            selectedDay,
            completionStatus.valueOrNull,
          ),
          if (selectedDay == 1 && widget.plan.description.trim().isNotEmpty)
            _buildAboutThisPlan(context),
          userPlanDayContent.when(
            data: (dayContentEither) {
              return dayContentEither.fold(
                (failure) => _buildDayContentError(),
                (dayContent) => ActivityList(
                  language: language,
                  tasks: dayContent.tasks,
                  today: selectedDay,
                  totalDays: dayContent.tasks.length,
                  planId: widget.plan.id,
                  dayNumber: selectedDay,
                  dayAudioUrl: dayContent.audioUrl,
                  onActivityToggled:
                      (taskId) => _handleTaskToggle(taskId, dayContent.tasks),
                  onReaderClosed: _onReaderClosed,
                ),
              );
            },
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
        Text(context.l10n.plan_no_tasks_error, style: TextStyle(color: Colors.red[600])),
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

  Widget _buildAboutThisPlan(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.about_this_plan.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.plan.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDayTitle(
    BuildContext context,
    String language,
    int day,
    Either<Failure, Map<int, bool>>? completionStatusEither,
  ) {
    final completionStatus = completionStatusEither?.fold(
      (_) => null,
      (status) => status,
    );
    final l10n = context.l10n;
    final totalDays = widget.plan.totalDays;
    final isLastDay = day == totalDays;
    final isFirstDay = day == 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Day $day of $totalDays',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        if (isLastDay)
          _StatusBadge(
            label: l10n.plan_status_last_day,
            color: Theme.of(context).colorScheme.primary,
          )
        else if (isFirstDay)
          _StatusBadge(
            label: l10n.plan_status_just_started,
            color: Colors.green,
          )
        else if (completionStatus != null)
          if (PlanUtils.calculateMissedDays(
                widget.startDate,
                widget.plan.startedAt,
                totalDays,
                completionStatus,
              ) >
              0)
            MissedDaysBadge(
              planStartDate: widget.startDate,
              userJoinDate: widget.plan.startedAt,
              totalDays: totalDays,
              completionStatus: completionStatus,
            )
          else
            const OnTrackBadge(),
      ],
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
      final resultEither =
          task.isCompleted
              ? await ref.read(deleteTaskFutureProvider(taskId).future)
              : await ref.read(completeTaskFutureProvider(taskId).future);

      resultEither.fold(
        (failure) {
          _logger.error('Error toggling task: ${failure.message}');
          if (mounted) {
            _showErrorSnackbar(context.l10n.updateTaskError);
          }
        },
        (success) {
          if (success && mounted) {
            ref.invalidate(
              userPlanDayContentFutureProvider(
                PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
              ),
            );
            // Also invalidate completion status to refresh checkmarks
            ref.invalidate(
              userPlanDaysCompletionStatusProvider(widget.plan.id),
            );
          } else if (!success && mounted) {
            _showErrorSnackbar(context.l10n.updateTaskError);
          }
        },
      );
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

  // ─── 3-dot options sheet ─────────────────────────────────────────────────

  void _showOptionsSheet(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve series membership so "About" can navigate immediately.
    final seriesAsync = ref.read(seriesListFutureProvider);
    ({Series series, int index})? seriesEntry;
    seriesAsync.whenOrNull(
      data: (either) => either.fold((_) => null, (list) {
        for (final s in list) {
          final idx = s.plans.indexWhere((p) => p.id == widget.plan.id);
          if (idx >= 0) {
            seriesEntry = (series: s, index: idx);
            return;
          }
        }
      }),
    );

    // Resolve reminder time for the subtitle on the Reminders row.
    final routineAsync = ref.read(userRoutineProvider);
    RoutineBlock? planBlock;
    routineAsync.whenOrNull(
      data: (data) {
        if (data == null) return;
        for (final b in data.blocks) {
          if (b.items.any((i) => i.id == widget.plan.id)) {
            planBlock = b;
            break;
          }
        }
      },
    );
    final reminderSubtitle = planBlock == null
        ? null
        : planBlock!.notificationEnabled
            ? formatRoutineTime(planBlock!.time)
            : l10n.reminders_turned_off;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              // About
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.plan_options_about),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  if (seriesEntry != null) {
                    context.pushNamed(
                      'home-series-detail',
                      pathParameters: {'id': seriesEntry!.series.id},
                      extra: {'series': seriesEntry!.series},
                    );
                  } else {
                    final plan = Plan(
                      id: widget.plan.id,
                      title: widget.plan.title,
                      description: widget.plan.description,
                      language: widget.plan.language,
                      authorId: '',
                      totalDays: widget.plan.totalDays,
                      difficulty: DifficultyLevel.beginner,
                      coverImageUrl: widget.plan.imageUrl,
                      startDate: widget.plan.startDate,
                    );
                    context.pushNamed(
                      'practice-plan-info',
                      extra: {'plan': plan},
                    );
                  }
                },
              ),
              // Reminders
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(l10n.plan_options_reminders),
                subtitle: reminderSubtitle != null
                    ? Text(reminderSubtitle)
                    : null,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showRemindersSheet(context);
                },
              ),
              // Unenroll
              ListTile(
                leading: Icon(
                  Icons.exit_to_app,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  l10n.plan_unenroll,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showUnenrollDialog(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ─── Reminders sheet ─────────────────────────────────────────────────────

  void _showRemindersSheet(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final routineData = ref.read(userRoutineProvider).valueOrNull;
    if (routineData == null ||
        routineData.apiRoutineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reminders_not_in_routine)),
      );
      return;
    }

    RoutineBlock? planBlock;
    for (final b in routineData.blocks) {
      if (b.items.any((i) => i.id == widget.plan.id)) {
        planBlock = b;
        break;
      }
    }

    if (planBlock == null || planBlock.apiTimeBlockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reminders_not_in_routine)),
      );
      return;
    }

    final block = planBlock;
    final routineId = routineData.apiRoutineId!;

    TimeOfDay selectedTime = block.time;
    bool reminderEnabled = block.notificationEnabled;
    bool isSaving = false;

    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> pickTime() async {
              TimeOfDay? picked;
              if (Platform.isIOS) {
                final now = DateTime.now();
                var selected = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                final confirmed = await showCupertinoModalPopup<bool>(
                  context: ctx,
                  builder: (popupCtx) => CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness:
                          isDark ? Brightness.dark : Brightness.light,
                    ),
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1C1E)
                            : Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                CupertinoButton(
                                  onPressed: () =>
                                      Navigator.of(popupCtx).pop(false),
                                  child: Text(l10n.cancel),
                                ),
                                CupertinoButton(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    Navigator.of(popupCtx).pop(true);
                                  },
                                  child: Text(l10n.done),
                                ),
                              ],
                            ),
                            Expanded(
                              child: CupertinoDatePicker(
                                mode: CupertinoDatePickerMode.time,
                                initialDateTime: selected,
                                use24hFormat: use24h,
                                onDateTimeChanged: (dt) => selected = dt,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                if (confirmed == true) {
                  picked = TimeOfDay(
                    hour: selected.hour,
                    minute: selected.minute,
                  );
                }
              } else {
                picked = await showTimePicker(
                  context: ctx,
                  initialTime: selectedTime,
                );
              }
              if (picked != null) {
                setSheetState(() => selectedTime = picked!);
              }
            }

            Future<void> save() async {
              setSheetState(() => isSaving = true);
              final updated = block.copyWith(
                time: selectedTime,
                notificationEnabled: reminderEnabled,
              );
              final request = routineBlockToRequest(updated);
              final result = await ref.read(updateTimeBlockUseCaseProvider)(
                routineId,
                block.apiTimeBlockId!,
                request,
              );
              if (!mounted) return;
              result.fold(
                (_) {
                  setSheetState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.unenrollError)),
                  );
                },
                (_) {
                  Navigator.of(sheetCtx).pop();
                  ref.invalidate(userRoutineProvider);
                  final msg = reminderEnabled
                      ? l10n.reminders_updated(
                          formatRoutineTime(selectedTime),
                        )
                      : l10n.reminders_turned_off;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.reminders_daily_title,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.reminders_subtitle,
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Time tap row
                      InkWell(
                        onTap: reminderEnabled ? pickTime : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            formatRoutineTime(selectedTime),
                            style: Theme.of(ctx)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: reminderEnabled
                                  ? null
                                  : (isDark
                                      ? Colors.white38
                                      : Colors.black26),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Remind me toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.reminders_remind_me,
                            style: Theme.of(ctx).textTheme.bodyLarge,
                          ),
                          Switch(
                            value: reminderEnabled,
                            onChanged: (v) =>
                                setSheetState(() => reminderEnabled = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isSaving ? null : save,
                          style: FilledButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white
                                : Colors.black,
                            foregroundColor: isDark
                                ? Colors.black
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.save),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUnenrollDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.plan_unenroll_title),
          content: Text(l10n.plan_unenroll_body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleUnenroll();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.plan_unenroll),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleUnenroll() async {
    try {
      final resultEither = await ref.read(
        userPlanUnsubscribeFutureProvider(widget.plan.id).future,
      );

      resultEither.fold(
        (failure) {
          _logger.error('Error unenrolling: ${failure.message}');
          if (mounted) {
            _showErrorSnackbar(context.l10n.unenrollError);
          }
        },
        (success) {
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
        },
      );
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

  void _startReading(List<UserTasksDto> tasks, {String? audioUrl}) {
    final planTextItems = PlanSubtaskNavigation.fromUserTasks(tasks);
    if (planTextItems.isEmpty) return;

    // Find first uncompleted item of any content type; fall back to first.
    final targetIndex = planTextItems.indexWhere((item) => !item.isCompleted);
    final index = targetIndex >= 0 ? targetIndex : 0;
    final target = planTextItems[index];

    final navigationContext = NavigationContext(
      source: NavigationSource.plan,
      planId: widget.plan.id,
      dayNumber: selectedDay,
      targetSegmentId: target.firstSegmentId,
      planTextItems: planTextItems,
      currentTextIndex: index,
      dayAudioUrl: audioUrl,
    );

    PlanNavigator.push(context, target, navigationContext)
        .then((_) => _onReaderClosed());
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

    // Extract tasks and audioUrl from Either type
    final dayData = dayContent.valueOrNull?.fold(
      (failure) => null,
      (d) => d,
    );
    final tasks = dayData?.tasks ?? <UserTasksDto>[];
    final audioUrl = dayData?.audioUrl;

    final hasReadableContent =
        tasks.isNotEmpty && tasks.any(PlanSubtaskNavigation.isUserTaskNavigable);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: hasReadableContent
                ? () => _startReading(tasks, audioUrl: audioUrl)
                : null,
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

/// Small outlined pill badge used for plan day-status labels
/// ("Just started", "Last day", etc.).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
