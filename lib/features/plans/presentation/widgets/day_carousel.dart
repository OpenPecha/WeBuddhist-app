import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class DayCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  final int selectedDay;
  final Function(int) onDaySelected;

  const DayCarousel({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: CarouselSlider.builder(
        options: CarouselOptions(
          aspectRatio: 1,
          height: 80,
          viewportFraction: 0.2, // Show ~4 items at once (60px + margins)
          enableInfiniteScroll: false,
          scrollPhysics: const ClampingScrollPhysics(), // Smoother scroll
          autoPlayCurve: Curves.easeInOut,
          autoPlayAnimationDuration: const Duration(milliseconds: 300),
          padEnds: false, // Remove extra padding at start/end
          initialPage: 0, // Start from the beginning
        ),
        itemCount: days.length,
        itemBuilder: (context, index, realIndex) {
          final day = days[index];
          final isSelected = selectedDay == day['day'];

          return GestureDetector(
            onTap: () => onDaySelected(day['day']),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFF1E3A8A)
                          : Theme.of(context).cardColor,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day['day']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day['date'],
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
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
