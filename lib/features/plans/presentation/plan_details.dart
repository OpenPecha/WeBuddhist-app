import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'widgets/plan_cover_image.dart';
import 'widgets/day_carousel.dart';
import 'widgets/activity_list.dart';

class PlanDetails extends ConsumerStatefulWidget {
  const PlanDetails({super.key});

  @override
  ConsumerState<PlanDetails> createState() => _PlanDetailsState();
}

class _PlanDetailsState extends ConsumerState<PlanDetails> {
  int selectedDay = 3; // Day 3 is selected by default
  int selectedActivity = -1; // No activity selected initially

  final List<String> activities = [
    'Read verse of the day',
    'Guided Scripture',
    'Meditate on the verse',
    'Pray',
    'Habit',
  ];

  final List<Map<String, dynamic>> days = [
    {'day': 1, 'date': 'Mar 04', 'completed': true},
    {'day': 2, 'date': 'Mar 05', 'completed': true},
    {'day': 3, 'date': 'Mar 06', 'completed': true},
    {'day': 4, 'date': 'Mar 07', 'completed': false},
    {'day': 5, 'date': 'Mar 08', 'completed': false},
    {'day': 6, 'date': 'Mar 09', 'completed': false},
    {'day': 7, 'date': 'Mar 10', 'completed': false},
    {'day': 8, 'date': 'Mar 11', 'completed': false},
    {'day': 9, 'date': 'Mar 12', 'completed': false},
    {'day': 10, 'date': 'Mar 13', 'completed': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Train your Mind',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const PlanCoverImage(imagePath: 'assets/images/bg.jpg'),
            DayCarousel(
              days: days,
              selectedDay: selectedDay,
              onDaySelected: (day) {
                setState(() {
                  selectedDay = day;
                });
              },
            ),
            ActivityList(
              activities: activities,
              selectedActivity: selectedActivity,
              onActivitySelected: (activity) {
                setState(() {
                  selectedActivity = activity;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
