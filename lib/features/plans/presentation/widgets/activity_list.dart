import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/plan_tasks_model.dart';

class ActivityList extends StatelessWidget {
  final List<PlanTasksModel> tasks;
  final int today;
  final int totalDays;
  final int selectedActivity;
  final Function(int) onActivitySelected;

  const ActivityList({
    super.key,
    required this.tasks,
    required this.today,
    required this.totalDays,
    required this.selectedActivity,
    required this.onActivitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Day $today of $totalDays",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return Row(
                children: [
                  Radio<int>(
                    value: index,
                    groupValue: selectedActivity,
                    onChanged: (value) {
                      if (value != null) {
                        onActivitySelected(value);
                      }
                    },
                    activeColor: const Color(0xFF1E3A8A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tasks[index].title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
