import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final totalDays = widget.days.length;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 88,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: totalDays,
        itemBuilder: (context, index) {
          final day = widget.days[index];
          final dayDate = localStartDate.add(Duration(days: day.dayNumber - 1));
          final isSelected = widget.selectedDay == day.dayNumber;
          final isCompleted = widget.dayCompletionStatus?[day.dayNumber] ?? false;
          final isToday = dayDate.isAtSameMomentAs(today);
          final isLastDay = day.dayNumber == totalDays;

          // Sub-label: "Last day" for final day, "dd MMM" otherwise.
          final subLabel = isLastDay
              ? l10n.plan_status_last_day
              : DateFormat('dd MMM').format(dayDate);

          final borderColor = isSelected ? primaryColor : Colors.transparent;
          final cardColor = isSelected
              ? (isDark
                  ? primaryColor.withValues(alpha: 0.15)
                  : primaryColor.withValues(alpha: 0.08))
              : Theme.of(context).cardColor;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onDaySelected(day.dayNumber);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 72,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isCompleted)
                    Positioned(
                      top: 4,
                      right: 6,
                      child: Icon(
                        Icons.check,
                        size: 13,
                        color: primaryColor,
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
                          color: isSelected ? primaryColor : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: isToday && !isSelected
                            ? BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(10),
                              )
                            : null,
                        child: Text(
                          subLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: isLastDay
                                ? primaryColor
                                : isToday && !isSelected
                                    ? Colors.white
                                    : null,
                            fontWeight: isLastDay ? FontWeight.w600 : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
