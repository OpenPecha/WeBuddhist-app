import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';

class Series {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final bool featured;
  final int totalDays;
  final List<Plan> plans;

  const Series({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.featured = false,
    this.totalDays = 0,
    this.plans = const [],
  });
}
