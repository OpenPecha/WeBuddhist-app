import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum RoutineItemType { plan, recitation }

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'type': type.name,
      };

  factory RoutineItem.fromJson(Map<String, dynamic> json) => RoutineItem(
        id: json['id'] as String,
        title: json['title'] as String,
        imageUrl: json['imageUrl'] as String?,
        type: RoutineItemType.values.byName(json['type'] as String),
      );
}

class RoutineBlock {
  final String id;
  final TimeOfDay time;
  final bool notificationEnabled;
  final List<RoutineItem> items;

  RoutineBlock({
    String? id,
    required this.time,
    this.notificationEnabled = true,
    this.items = const [],
  }) : id = id ?? _uuid.v4();

  RoutineBlock copyWith({
    String? id,
    TimeOfDay? time,
    bool? notificationEnabled,
    List<RoutineItem>? items,
  }) {
    return RoutineBlock(
      id: id ?? this.id,
      time: time ?? this.time,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      items: items ?? this.items,
    );
  }

  int get timeInMinutes => time.hour * 60 + time.minute;

  /// Unique notification ID derived from block UUID.
  /// Offset by 100 to avoid collision with existing IDs (daily=1, recitation=2).
  int get notificationId => id.hashCode.abs() % 100000 + 100;

  String get formattedTime {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': time.hour,
        'minute': time.minute,
        'notificationEnabled': notificationEnabled,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory RoutineBlock.fromJson(Map<String, dynamic> json) => RoutineBlock(
        id: json['id'] as String,
        time: TimeOfDay(
          hour: json['hour'] as int,
          minute: json['minute'] as int,
        ),
        notificationEnabled: json['notificationEnabled'] as bool? ?? true,
        items: (json['items'] as List<dynamic>)
            .map((i) => RoutineItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class RoutineData {
  final List<RoutineBlock> blocks;

  const RoutineData({this.blocks = const []});

  bool get isEmpty => blocks.isEmpty;
  bool get hasItems => blocks.any((b) => b.items.isNotEmpty);

  /// Returns a new RoutineData with blocks sorted by time ascending.
  RoutineData get sortedByTime {
    final sorted = List<RoutineBlock>.from(blocks)
      ..sort((a, b) => a.timeInMinutes.compareTo(b.timeInMinutes));
    return RoutineData(blocks: sorted);
  }

  Map<String, dynamic> toJson() => {
        'blocks': blocks.map((b) => b.toJson()).toList(),
      };

  factory RoutineData.fromJson(Map<String, dynamic> json) => RoutineData(
        blocks: (json['blocks'] as List<dynamic>)
            .map((b) => RoutineBlock.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
}
