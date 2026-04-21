import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../day_carousel.dart';
import '../plan_cover_image.dart';
import 'preview_activity_list.dart';

/// A preview screen for viewing plan content before enrollment.
/// Unlike PlanDetails, this screen:
/// - Uses Plan domain entity
/// - Has no completion status tracking
/// - Has no task toggle functionality (read-only preview)
/// - Has "Start Reading" button to begin reading without enrolling
class PlanPreviewDetails extends ConsumerStatefulWidget {
  const PlanPreviewDetails({super.key, required this.plan});

  final Plan plan;

  @override
  ConsumerState<PlanPreviewDetails> createState() => _PlanPreviewDetailsState();
}

class _PlanPreviewDetailsState extends ConsumerState<PlanPreviewDetails> {
  int selectedDay = 1;

  bool _isPlanInRoutine(RoutineData routineData) {
    return routineData.blocks.any(
      (block) => block.items.any(
        (item) =>
            item.id == widget.plan.id && item.type == RoutineItemType.plan,
      ),
    );
  }

  void _handleAddToRoutine() {
    final isGuest = ref.read(authProvider).isGuest;
    if (isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }
    context.pushNamed(
      'edit-routine',
      extra: {'initialPlan': widget.plan},
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.plan.language;
    final authState = ref.watch(authProvider);
    final isGuest = authState.isGuest;
    final alreadyInRoutine = _isCurrentlyInRoutine();

    return Scaffold(
      appBar: _buildAppBar(context, alreadyInRoutine),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlanCoverImage(imageUrl: widget.plan.coverImageUrl ?? ''),
                  _buildDayCarouselSection(language),
                  _buildDayContentSection(context, language),
                ],
              ),
            ),
          ),
          if (!alreadyInRoutine)
            _buildBottomButton(context, isGuest),
        ],
      ),
    );
  }

  bool _isCurrentlyInRoutine() {
    final routineAsync = ref.watch(userRoutineProvider);
    final routineData = routineAsync.valueOrNull;
    if (routineData == null) return false;
    return _isPlanInRoutine(routineData);
  }

  AppBar _buildAppBar(BuildContext context, bool alreadyInRoutine) {
    return AppBar(
      title: Text(widget.plan.title, style: const TextStyle(fontSize: 20)),
      elevation: 0,
      actions: [
        if (alreadyInRoutine)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.plan_enrolled,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.check, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDayCarouselSection(String language) {
    final planDays = ref.watch(planDaysByPlanIdFutureProvider(widget.plan.id));

    return planDays.when(
      data: (daysEither) {
        return daysEither.fold(
          (failure) => _buildEmptyDayCarouselState(context),
          (days) {
            if (days.isEmpty) {
              return _buildEmptyDayCarouselState(context);
            }
            return _buildDayCarousel(language, days);
          },
        );
      },
      loading: () => const DayCarouselSkeleton(),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayTitle(context, language, selectedDay),
          dayContent.when(
            data: (contentEither) {
              return contentEither.fold(
                (failure) => _buildDayContentError(context),
                (content) => PreviewActivityList(
                  language: language,
                  tasks: content.tasks ?? [],
                  today: selectedDay,
                  totalDays: widget.plan.totalDays,
                  planId: widget.plan.id,
                  dayNumber: selectedDay,
                ),
              );
            },
            loading: () => const DayContentSkeleton(),
            error: (error, stackTrace) => _buildDayContentError(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDayContentError(BuildContext context) {
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
          child: Text(context.l10n.retry),
        ),
      ],
    );
  }

  Widget _buildEmptyDayCarouselState(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(child: Text(context.l10n.no_days_available)),
    );
  }

  Widget _buildDayTitle(BuildContext context, String language, int day) {
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        "Days $day of ${widget.plan.totalDays}",
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: "Inter",
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, bool isGuest) {
    return _AddToRoutineButton(
      label: context.l10n.routine_add_plan_to_routine,
      onPressed: _handleAddToRoutine,
    );
  }
}

class _AddToRoutineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _AddToRoutineButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.scaffoldBackgroundLight : AppColors.scaffoldBackgroundDark;
    final foregroundColor =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryDark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
              disabledForegroundColor: foregroundColor.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
