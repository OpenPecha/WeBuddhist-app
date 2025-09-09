import 'package:flutter/material.dart';

class ActivityList extends StatelessWidget {
  final List<String> activities;
  final int selectedActivity;
  final Function(int) onActivitySelected;
  final String title;

  const ActivityList({
    super.key,
    required this.activities,
    required this.selectedActivity,
    required this.onActivitySelected,
    this.title = 'Today\'s Activities',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
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
                        activities[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
