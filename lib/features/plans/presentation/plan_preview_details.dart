import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/plans/data/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'widgets/day_carousel.dart';
import 'widgets/plan_cover_image.dart';
import 'widgets/preview_activity_list.dart';

/// A preview screen for viewing plan content before enrollment.
/// Unlike PlanDetails, this screen:
/// - Uses PlansModel (non-enrolled data)
/// - Has no completion status tracking
/// - Has no task toggle functionality (read-only preview)
/// - Has "Start Reading" button to begin reading without enrolling
class PlanPreviewDetails extends ConsumerStatefulWidget {
  const PlanPreviewDetails({super.key, required this.plan});

  final PlansModel plan;

  @override
  ConsumerState<PlanPreviewDetails> createState() => _PlanPreviewDetailsState();
}

class _PlanPreviewDetailsState extends ConsumerState<PlanPreviewDetails> {
  int selectedDay = 1;

  @override
  Widget build(BuildContext context) {
    final language = widget.plan.language;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  PlanCoverImage(imageUrl: widget.plan.imageUrl ?? ''),
                  _buildDayCarouselSection(language),
                  _buildDayContentSection(context, language),
                ],
              ),
            ),
          ),
          _buildStartReadingButton(context, localizations, language),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(widget.plan.title, style: const TextStyle(fontSize: 20)),
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
        return _buildDayCarousel(language, days);
      },
      loading: () => _buildDayCarouselLoadingPlaceholder(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildDayCarousel(String language, List<PlanDaysModel> days) {
    return DayCarousel(
      language: language,
      days: days,
      selectedDay: selectedDay,
      startDate: DateTime.now(),
      dayCompletionStatus: null, // No completion status in preview mode
      onDaySelected: (day) {
        setState(() {
          selectedDay = day;
        });
      },
    );
  }

  Widget _buildDayContentSection(BuildContext context, String language) {
    final dayContent = ref.watch(
      planDayContentFutureProvider(
        PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayTitle(context, language, selectedDay),
          dayContent.when(
            data:
                (content) => PreviewActivityList(
                  language: language,
                  tasks: content.tasks ?? [],
                  today: selectedDay,
                  totalDays: widget.plan.totalDays ?? 0,
                ),
            loading:
                () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
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
          'Unable to load the tasks for the day',
          style: TextStyle(color: Colors.red[600]),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            ref.invalidate(planDayContentFutureProvider);
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildEmptyDayCarouselState(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(child: Text(localizations.no_days_available)),
    );
  }

  Widget _buildDayTitle(BuildContext context, String language, int day) {
    return Text(
      "Days $day of ${widget.plan.totalDays ?? 0}",
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: "Inter",
      ),
    );
  }

  Widget _buildDayCarouselLoadingPlaceholder() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 70,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartReadingButton(
    BuildContext context,
    AppLocalizations localizations,
    String language,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _handleStartReading(context),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              localizations.start_reading,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  void _handleStartReading(BuildContext context) {
    // Get the first day's content and navigate to the first subtask's text
    final dayContent = ref.read(
      planDayContentFutureProvider(
        PlanDaysParams(planId: widget.plan.id, dayNumber: 1),
      ),
    );

    dayContent.whenData((content) {
      final tasks = content.tasks;
      if (tasks != null && tasks.isNotEmpty) {
        // Find the first subtask that has a sourceTextId
        for (final task in tasks) {
          for (final subtask in task.subtasks) {
            if (subtask.sourceTextId != null &&
                subtask.sourceTextId!.isNotEmpty) {
              context.push(
                '/practice/texts/${subtask.sourceTextId}',
                extra: {
                  if (subtask.pechaSegmentId != null)
                    'segmentId': subtask.pechaSegmentId,
                },
              );
              return;
            }
          }
        }
      }
    });
  }
}
