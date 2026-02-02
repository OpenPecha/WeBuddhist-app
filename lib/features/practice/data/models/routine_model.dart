import 'package:flutter/material.dart';

class RoutineItem {
  final String id;
  final String title;
  final String? imageUrl;
  final RoutineItemType type;

  const RoutineItem({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.type,
  });
}

enum RoutineItemType { plan, recitation }

class RoutineBlock {
  final TimeOfDay time;
  final bool notificationEnabled;
  final List<RoutineItem> items;

  const RoutineBlock({
    required this.time,
    this.notificationEnabled = true,
    this.items = const [],
  });

  RoutineBlock copyWith({
    TimeOfDay? time,
    bool? notificationEnabled,
    List<RoutineItem>? items,
  }) {
    return RoutineBlock(
      time: time ?? this.time,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      items: items ?? this.items,
    );
  }

  String get formattedTime {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class RoutineData {
  final List<RoutineBlock> blocks;

  const RoutineData({this.blocks = const []});

  bool get isEmpty => blocks.isEmpty;
  bool get hasItems => blocks.any((b) => b.items.isNotEmpty);
}
