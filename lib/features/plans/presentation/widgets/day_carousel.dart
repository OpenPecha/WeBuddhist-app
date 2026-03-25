import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_pecha/features/plans/models/plan_days_model.dart';
import 'package:intl/intl.dart';

class DayCarousel extends StatelessWidget {
  final String language;
  final List<PlanDaysModel> days;
  final DateTime startDate;
  final int selectedDay;
  final Function(int) onDaySelected;
  final Map<int, bool>? dayCompletionStatus;

  const DayCarousel({
    super.key,
    required this.language,
    required this.days,
    required this.startDate,
    required this.selectedDay,
    required this.onDaySelected,
    this.dayCompletionStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Convert to local time first, then extract date-only to avoid
    // timezone-related date shifts when the time component crosses midnight
    final localStartDate = DateUtils.dateOnly(startDate.toLocal());
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedIndex = days.indexWhere((d) => d.dayNumber == selectedDay);
    final initialPage = selectedIndex >= 0 ? selectedIndex : 0;

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: CarouselSlider.builder(
        options: CarouselOptions(
          aspectRatio: 1,
          height: 70,
          viewportFraction: 0.24,
          enableInfiniteScroll: false,
          scrollPhysics: const ClampingScrollPhysics(),
          autoPlayCurve: Curves.easeInOut,
          autoPlayAnimationDuration: const Duration(milliseconds: 300),
          padEnds: false,
          initialPage: initialPage,
        ),
        itemCount: days.length,
        itemBuilder: (context, index, realIndex) {
          final day = days[index];
          final dayDate = localStartDate.add(Duration(days: day.dayNumber - 1));
          final dayDateString = DateFormat('dd MMM').format(dayDate);
          final isSelected = selectedDay == day.dayNumber;
          final isCompleted = dayCompletionStatus?[day.dayNumber] ?? false;
          final isToday = dayDate.isAtSameMomentAs(today);

          return GestureDetector(
            onTap: () => onDaySelected(day.dayNumber),
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFF1E3A8A)
                          : Theme.of(context).cardColor,
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isCompleted)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.dayNumber}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration:
                            isToday
                                ? BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(12),
                                )
                                : null,
                        child: Text(
                          dayDateString,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isToday
                                    ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.white)
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
