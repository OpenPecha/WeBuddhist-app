/// Navigation source types for reader
enum NavigationSource {
  normal,
  search,
  plan,
  deepLink,
}

/// Represents a text item within a plan for swipe navigation
class PlanTextItem {
  final String textId;
  final String? segmentId;
  final String title;

  /// The subtask ID associated with this text item.
  /// When non-null, navigating to this item will auto-track subtask completion.
  /// Left null in preview mode to prevent tracking for unenrolled plans.
  final String? subtaskId;

  const PlanTextItem({
    required this.textId,
    this.segmentId,
    required this.title,
    this.subtaskId,
  });

  PlanTextItem copyWith({
    String? textId,
    String? segmentId,
    String? title,
    String? subtaskId,
  }) {
    return PlanTextItem(
      textId: textId ?? this.textId,
      segmentId: segmentId ?? this.segmentId,
      title: title ?? this.title,
      subtaskId: subtaskId ?? this.subtaskId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanTextItem &&
        other.textId == textId &&
        other.segmentId == segmentId &&
        other.title == title &&
        other.subtaskId == subtaskId;
  }

  @override
  int get hashCode => Object.hash(textId, segmentId, title, subtaskId);

  @override
  String toString() {
    return 'PlanTextItem(textId: $textId, segmentId: $segmentId, title: $title, subtaskId: $subtaskId)';
  }
}

/// Context for navigation to reader screen
/// Contains information about the navigation source and plan context for swipe navigation
class NavigationContext {
  final NavigationSource source;
  final String? planId;
  final int? dayNumber;
  final String? targetSegmentId;
  final List<PlanTextItem>? planTextItems;
  final int? currentTextIndex;

  const NavigationContext({
    required this.source,
    this.planId,
    this.dayNumber,
    this.targetSegmentId,
    this.planTextItems,
    this.currentTextIndex,
  });

  /// Check if this navigation context supports swipe navigation
  bool get canSwipe =>
      source == NavigationSource.plan &&
      planTextItems != null &&
      planTextItems!.length > 1;

  /// Check if there is a next text in the plan
  bool get hasNextText =>
      canSwipe &&
      currentTextIndex != null &&
      currentTextIndex! < planTextItems!.length - 1;

  /// Check if there is a previous text in the plan
  bool get hasPreviousText =>
      canSwipe && currentTextIndex != null && currentTextIndex! > 0;

  /// Get the next text item in the plan
  PlanTextItem? get nextTextItem {
    if (!hasNextText) return null;
    return planTextItems![currentTextIndex! + 1];
  }

  /// Get the previous text item in the plan
  PlanTextItem? get previousTextItem {
    if (!hasPreviousText) return null;
    return planTextItems![currentTextIndex! - 1];
  }

  NavigationContext copyWith({
    NavigationSource? source,
    String? planId,
    int? dayNumber,
    String? targetSegmentId,
    List<PlanTextItem>? planTextItems,
    int? currentTextIndex,
  }) {
    return NavigationContext(
      source: source ?? this.source,
      planId: planId ?? this.planId,
      dayNumber: dayNumber ?? this.dayNumber,
      targetSegmentId: targetSegmentId ?? this.targetSegmentId,
      planTextItems: planTextItems ?? this.planTextItems,
      currentTextIndex: currentTextIndex ?? this.currentTextIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationContext &&
        other.source == source &&
        other.planId == planId &&
        other.dayNumber == dayNumber &&
        other.targetSegmentId == targetSegmentId &&
        other.currentTextIndex == currentTextIndex;
  }

  @override
  int get hashCode => Object.hash(
    source,
    planId,
    dayNumber,
    targetSegmentId,
    currentTextIndex,
  );

  @override
  String toString() {
    return 'NavigationContext(source: $source, planId: $planId, dayNumber: $dayNumber, targetSegmentId: $targetSegmentId, currentTextIndex: $currentTextIndex)';
  }
}
