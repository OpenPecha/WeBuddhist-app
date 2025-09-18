import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/data/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'widgets/plan_cover_image.dart';
import 'widgets/day_carousel.dart';
import 'widgets/activity_list.dart';

class PlanDetails extends ConsumerStatefulWidget {
  const PlanDetails({super.key, required this.plan});
  final PlansModel plan;

  @override
  ConsumerState<PlanDetails> createState() => _PlanDetailsState();
}

class _PlanDetailsState extends ConsumerState<PlanDetails> {
  int selectedDay = 1; // Day 3 is selected by default
  Set<int> selectedActivities = {}; // No activities selected initially

  @override
  Widget build(BuildContext context) {
    final DateTime startDate = DateTime.now();
    final planDays = ref.watch(planDaysByPlanIdFutureProvider(widget.plan.id));
    final planDayContent = ref.watch(
      planDayContentFutureProvider(
        PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.plan.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PlanCoverImage(imageUrl: widget.plan.imageUrl ?? ''),
            DayCarousel(
              days: planDays.value ?? [],
              selectedDay: selectedDay,
              startDate: startDate,
              onDaySelected: (day) {
                setState(() {
                  selectedDay = day;
                });
              },
            ),
            ActivityList(
              tasks: planDayContent.value?.tasks ?? [],
              today: selectedDay,
              totalDays: widget.plan.totalDays,
              selectedActivities: selectedActivities,
              onActivityToggled: (activity) {
                setState(() {
                  if (selectedActivities.contains(activity)) {
                    selectedActivities.remove(activity);
                  } else {
                    selectedActivities.add(activity);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
