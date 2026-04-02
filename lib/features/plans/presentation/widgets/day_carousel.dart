import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:intl/intl.dart';

class DayCarousel extends StatefulWidget {
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
  State<DayCarousel> createState() => _DayCarouselState();
}

class _DayCarouselState extends State<DayCarousel> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDay(animate: false);
    });
  }

  @override
  void didUpdateWidget(DayCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay) {
      _scrollToSelectedDay(animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDay({required bool animate}) {
    final selectedIndex = widget.days.indexWhere(
      (d) => d.dayNumber == widget.selectedDay,
    );
    
    if (selectedIndex < 0 || !_scrollController.hasClients) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = 88.0;
    final targetOffset = (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (animate) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(clampedOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localStartDate = DateUtils.dateOnly(widget.startDate.toLocal());
    final today = DateUtils.dateOnly(DateTime.now());

    return SizedBox(
      height: 80,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: widget.days.length,
        itemBuilder: (context, index) {
          final day = widget.days[index];
          final dayDate = localStartDate.add(Duration(days: day.dayNumber - 1));
          final dayDateString = DateFormat('dd MMM').format(dayDate);
          final isSelected = widget.selectedDay == day.dayNumber;
          final isCompleted = widget.dayCompletionStatus?[day.dayNumber] ?? false;
          final isToday = dayDate.isAtSameMomentAs(today);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onDaySelected(day.dayNumber);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1E3A8A)
                      : Theme.of(context).cardColor,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
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
                        style: const TextStyle(
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
                        decoration: isToday
                            ? BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(12),
                              )
                            : null,
                        child: Text(
                          dayDateString,
                          style: TextStyle(
                            fontSize: 11,
                            color: isToday ? Colors.white : null,
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
