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

  /// Safely parses a [RoutineItem] from JSON with null checks and fallbacks.
  /// Returns null if required fields (id, title) are missing or invalid.
  static RoutineItem? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final id = json['id'];
    final title = json['title'];

    // Required fields must be non-null strings
    if (id is! String || id.isEmpty) return null;
    if (title is! String) return null;

    return RoutineItem(
      id: id,
      title: title,
      imageUrl: json['imageUrl'] as String?,
      type: _parseRoutineItemType(json['type']),
    );
  }

  factory RoutineItem.fromJson(Map<String, dynamic> json) {
    final item = tryFromJson(json);
    if (item == null) {
      throw FormatException('Invalid RoutineItem JSON: $json');
    }
    return item;
  }

  /// Safely parses [RoutineItemType] with fallback to [RoutineItemType.plan].
  static RoutineItemType _parseRoutineItemType(dynamic value) {
    if (value is! String) return RoutineItemType.plan;
    return RoutineItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RoutineItemType.plan,
    );
  }
}

class RoutineBlock {
  final String id;
  final TimeOfDay time;
  final bool notificationEnabled;
  final List<RoutineItem> items;

  /// Persisted notification ID for stable scheduling across app restarts.
  /// This is stored to ensure the same block always uses the same notification ID.
  final int? _persistedNotificationId;

  RoutineBlock({
    String? id,
    required this.time,
    this.notificationEnabled = true,
    this.items = const [],
    int? notificationId,
  })  : id = id ?? _uuid.v4(),
        _persistedNotificationId = notificationId;

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
      notificationId: _persistedNotificationId ?? notificationId,
    );
  }

  int get timeInMinutes => time.hour * 60 + time.minute;

  /// Unique notification ID for this block.
  ///
  /// Uses a stable algorithm that:
  /// 1. Persists the ID once generated (stored in JSON)
  /// 2. Falls back to a collision-resistant hash if not persisted
  ///
  /// Range: 1000-999999 to avoid collision with:
  /// - System IDs (0-99)
  /// - Legacy notification IDs (100-999)
  int get notificationId {
    if (_persistedNotificationId != null) {
      return _persistedNotificationId;
    }
    return _generateStableNotificationId(id);
  }

  /// Generates a stable notification ID from UUID string.
  /// Uses FNV-1a hash for better distribution than hashCode.
  static int _generateStableNotificationId(String uuid) {
    // FNV-1a 32-bit hash
    const int fnvPrime = 0x01000193;
    const int fnvOffset = 0x811c9dc5;

    int hash = fnvOffset;
    for (int i = 0; i < uuid.length; i++) {
      hash ^= uuid.codeUnitAt(i);
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }

    // Map to range 1000-999999 (998,999 possible values)
    return (hash.abs() % 998999) + 1000;
  }

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
    'notificationId': notificationId, // Persist for stability
    'items': items.map((i) => i.toJson()).toList(),
  };

  /// Safely parses a [RoutineBlock] from JSON with null checks and fallbacks.
  /// Returns null if required fields are missing or invalid.
  static RoutineBlock? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final id = json['id'];
    final hour = json['hour'];
    final minute = json['minute'];

    // Required fields validation
    if (id is! String || id.isEmpty) return null;
    if (hour is! int || hour < 0 || hour > 23) return null;
    if (minute is! int || minute < 0 || minute > 59) return null;

    // Parse items safely, filtering out invalid ones
    final itemsList = json['items'];
    final items = <RoutineItem>[];
    if (itemsList is List) {
      for (final itemJson in itemsList) {
        if (itemJson is Map<String, dynamic>) {
          final item = RoutineItem.tryFromJson(itemJson);
          if (item != null) {
            items.add(item);
          }
        }
      }
    }

    return RoutineBlock(
      id: id,
      time: TimeOfDay(hour: hour, minute: minute),
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      notificationId: json['notificationId'] as int?,
      items: items,
    );
  }

  factory RoutineBlock.fromJson(Map<String, dynamic> json) {
    final block = tryFromJson(json);
    if (block == null) {
      throw FormatException('Invalid RoutineBlock JSON: $json');
    }
    return block;
  }
}

class RoutineData {
  /// Maximum number of time blocks allowed per routine.
  static const int maxBlocks = 20;

  final List<RoutineBlock> blocks;

  const RoutineData({this.blocks = const []});

  bool get isEmpty => blocks.isEmpty;
  bool get hasItems => blocks.any((b) => b.items.isNotEmpty);

  /// Whether the maximum block limit has been reached.
  bool get isAtMaxBlocks => blocks.length >= maxBlocks;

  /// Returns a new RoutineData with blocks sorted by time ascending.
  RoutineData get sortedByTime {
    final sorted = List<RoutineBlock>.from(blocks)
      ..sort((a, b) => a.timeInMinutes.compareTo(b.timeInMinutes));
    return RoutineData(blocks: sorted);
  }

  Map<String, dynamic> toJson() => {
    'blocks': blocks.map((b) => b.toJson()).toList(),
  };

  /// Safely parses [RoutineData] from JSON with null checks.
  /// Invalid blocks are filtered out rather than causing a crash.
  static RoutineData? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final blocksList = json['blocks'];
    if (blocksList is! List) return const RoutineData();

    final blocks = <RoutineBlock>[];
    for (final blockJson in blocksList) {
      if (blockJson is Map<String, dynamic>) {
        final block = RoutineBlock.tryFromJson(blockJson);
        if (block != null) {
          blocks.add(block);
        }
      }
    }

    return RoutineData(blocks: blocks);
  }

  factory RoutineData.fromJson(Map<String, dynamic> json) {
    return tryFromJson(json) ?? const RoutineData();
  }
}
