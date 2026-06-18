import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';

class DayCompletionBottomSheet extends StatelessWidget {
  final int dayNumber;
  final int totalDays;
  final int completedDays;
  final String? imageUrl;
  final String planTitle;

  const DayCompletionBottomSheet({
    super.key,
    required this.dayNumber,
    required this.totalDays,
    required this.completedDays,
    required this.imageUrl,
    required this.planTitle,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalDays > 0 ? completedDays / totalDays : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(context),
          const SizedBox(height: 20),
          _buildCheckmarkIcon(context),
          const SizedBox(height: 15),
          _buildDayText(context),
          const SizedBox(height: 20),
          _buildPlanImageCard(context),
          const SizedBox(height: 30),
          _buildProgressBar(context, progress),
          const SizedBox(height: 25)
        ],
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
          alpha: 0.4,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildCheckmarkIcon(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.check,
        size: 30,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildDayText(BuildContext context) {
    return Text(
      'Day $dayNumber of $totalDays',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPlanImageCard(BuildContext context) {
    final imageWidth = MediaQuery.of(context).size.width - 80;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholderImage(context, imageWidth);
    }

    return CachedNetworkImageWidget(
      imageUrl: imageUrl!,
      width: imageWidth,
      height: 160,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context, double width) {
    return Container(
      width: width,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double progress) {
    final barWidth = MediaQuery.of(context).size.width - 80;

    return SizedBox(
      width: barWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 5,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.12),
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}
