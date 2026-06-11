/// Navigation source types for reader
enum NavigationSource {
  normal,
  search,
  plan,
  deepLink,
}

/// Discriminator for the kind of content a [PlanTextItem] carries.
///
/// - [sourceReference] points at a remote text via [PlanTextItem.textId]
///   and is rendered by `ReaderScreen`.
/// - [inlineText] carries inline content via [PlanTextItem.inlineContent]
///   and is rendered by `PlanTextScreen`.
enum PlanItemContentType {
  sourceReference,
  inlineText,
}

/// API-level content type strings used by the plan endpoints.
class PlanContentTypes {
  PlanContentTypes._();

  static const String sourceReference = 'SOURCE_REFERENCE';
  static const String text = 'TEXT';

  /// Map a raw API value to a [PlanItemContentType], or null if unknown.
  static PlanItemContentType? parse(String? raw) {
    switch (raw) {
      case sourceReference:
        return PlanItemContentType.sourceReference;
      case text:
        return PlanItemContentType.inlineText;
      default:
        return null;
    }
  }
}

/// Represents a navigable subtask within a plan.
///
/// Plan subtasks come in two flavours, both of which appear in the same
/// linear navigation strip ("1 of N", "2 of N", ...):
///
/// - **SOURCE_REFERENCE** — opens `ReaderScreen` for [textId] and scrolls
///   to the first segment in [segmentIds]. Has full reader features
///   (commentary, copy/share, search, language, audio, ...).
/// - **TEXT** — opens `PlanTextScreen` and renders [inlineContent] directly.
///   Stripped-down view: title in app bar, font size control, no other
///   reader features.
///
/// Construct via [PlanTextItem.sourceReference] or [PlanTextItem.inlineText]
/// to get compile-time validation of which fields are required.
class PlanTextItem {
  final PlanItemContentType contentType;

  /// SOURCE_REFERENCE only: the remote text id used by the route
  /// `/reader/:textId`. Empty string for inline TEXT items.
  final String textId;

  /// SOURCE_REFERENCE only: ordered list of segments to scroll through.
  /// Null/empty for inline TEXT items.
  final List<String>? segmentIds;

  /// TEXT only: the inline content rendered by `PlanTextScreen`.
  /// Null for SOURCE_REFERENCE items.
  final String? inlineContent;

  /// Display title used in app bars and bottom-bar progress text.
  final String title;

  /// The subtask ID associated with this item.
  /// When non-null, navigating away from this item will mark the subtask
  /// complete. Left null in preview mode to prevent tracking for
  /// unenrolled plans.
  final String? subtaskId;

  /// The parent task ID. Used to look up audio windows in
  /// [PlanDayAudioNotifier] — null for preview (unenrolled) items.
  final String? taskId;

  /// Whether the subtask is already completed. Prevents duplicate
  /// completion API calls.
  final bool isCompleted;

  /// This subtask's own audio file URL, if any. When present it takes
  /// precedence over the day-level audio track (see
  /// [NavigationContext.effectiveAudioUrlFor]). Null when the subtask has no
  /// dedicated audio.
  final String? audioUrl;

  /// Audio segment start offset in milliseconds. For a subtask-level
  /// [audioUrl] this is an offset within that file; for the day-level track
  /// it is an offset within the day audio. Defaults to 0 when null.
  final int? startMs;

  /// Audio segment end offset in milliseconds. When null, playback runs to the
  /// natural end of the resolved file (the common case for per-subtask audio).
  final int? endMs;

  const PlanTextItem._({
    required this.contentType,
    required this.textId,
    required this.title,
    this.segmentIds,
    this.inlineContent,
    this.subtaskId,
    this.taskId,
    this.isCompleted = false,
    this.audioUrl,
    this.startMs,
    this.endMs,
  });

  /// Build a SOURCE_REFERENCE item. Throws if [textId] is empty.
  factory PlanTextItem.sourceReference({
    required String textId,
    required String title,
    List<String>? segmentIds,
    String? subtaskId,
    String? taskId,
    bool isCompleted = false,
    String? audioUrl,
    int? startMs,
    int? endMs,
  }) {
    assert(textId.isNotEmpty, 'sourceReference requires non-empty textId');
    return PlanTextItem._(
      contentType: PlanItemContentType.sourceReference,
      textId: textId,
      title: title,
      segmentIds: segmentIds,
      subtaskId: subtaskId,
      taskId: taskId,
      isCompleted: isCompleted,
      audioUrl: audioUrl,
      startMs: startMs,
      endMs: endMs,
    );
  }

  /// Build a TEXT item. Throws if [content] is blank.
  factory PlanTextItem.inlineText({
    required String content,
    required String title,
    String? subtaskId,
    String? taskId,
    bool isCompleted = false,
    String? audioUrl,
    int? startMs,
    int? endMs,
  }) {
    assert(content.trim().isNotEmpty, 'inlineText requires non-blank content');
    return PlanTextItem._(
      contentType: PlanItemContentType.inlineText,
      textId: '',
      inlineContent: content,
      title: title,
      subtaskId: subtaskId,
      taskId: taskId,
      isCompleted: isCompleted,
      audioUrl: audioUrl,
      startMs: startMs,
      endMs: endMs,
    );
  }

  /// True if this item is a SOURCE_REFERENCE.
  bool get isSourceReference =>
      contentType == PlanItemContentType.sourceReference;

  /// True if this item is an inline TEXT item.
  bool get isInlineText => contentType == PlanItemContentType.inlineText;

  /// Get the first segment ID for initial scroll position
  /// (SOURCE_REFERENCE only).
  String? get firstSegmentId =>
      segmentIds?.isNotEmpty == true ? segmentIds!.first : null;

  PlanTextItem copyWith({
    PlanItemContentType? contentType,
    String? textId,
    List<String>? segmentIds,
    String? inlineContent,
    String? title,
    String? subtaskId,
    String? taskId,
    bool? isCompleted,
    String? audioUrl,
    int? startMs,
    int? endMs,
  }) {
    return PlanTextItem._(
      contentType: contentType ?? this.contentType,
      textId: textId ?? this.textId,
      segmentIds: segmentIds ?? this.segmentIds,
      inlineContent: inlineContent ?? this.inlineContent,
      title: title ?? this.title,
      subtaskId: subtaskId ?? this.subtaskId,
      taskId: taskId ?? this.taskId,
      isCompleted: isCompleted ?? this.isCompleted,
      audioUrl: audioUrl ?? this.audioUrl,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlanTextItem) return false;
    if (other.contentType != contentType ||
        other.textId != textId ||
        other.title != title ||
        other.inlineContent != inlineContent ||
        other.subtaskId != subtaskId ||
        other.taskId != taskId ||
        other.isCompleted != isCompleted ||
        other.audioUrl != audioUrl ||
        other.startMs != startMs ||
        other.endMs != endMs) {
      return false;
    }
    if (segmentIds == null && other.segmentIds == null) return true;
    if (segmentIds == null || other.segmentIds == null) return false;
    if (segmentIds!.length != other.segmentIds!.length) return false;
    for (int i = 0; i < segmentIds!.length; i++) {
      if (segmentIds![i] != other.segmentIds![i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        contentType,
        textId,
        Object.hashAll(segmentIds ?? const []),
        inlineContent,
        title,
        subtaskId,
        taskId,
        isCompleted,
        audioUrl,
        startMs,
        endMs,
      );

  @override
  String toString() {
    return 'PlanTextItem(contentType: $contentType, textId: $textId, '
        'title: $title, subtaskId: $subtaskId, isCompleted: $isCompleted)';
  }
}

enum SwipeDirection { next, previous } // Direction for swipe/button navigation

/// Context for navigation to reader / plan-text screens.
/// Contains information about the navigation source and the linear list
/// of plan subtasks for swipe / arrow navigation between them.
class NavigationContext {
  final NavigationSource source;
  final String? planId;
  final int? dayNumber;
  final String? targetSegmentId;
  final List<PlanTextItem>? planTextItems;
  final int? currentTextIndex;
  final SwipeDirection? navigationDirection; // slide direction (left/right)
  /// When true, the reader should auto-play this item's audio segment on open.
  final bool autoPlay;
  /// The day-level audio URL shared by all tasks in this plan day.
  final String? dayAudioUrl;

  const NavigationContext({
    required this.source,
    this.planId,
    this.dayNumber,
    this.targetSegmentId,
    this.planTextItems,
    this.currentTextIndex,
    this.navigationDirection,
    this.autoPlay = false,
    this.dayAudioUrl,
  });

  /// Whether this context can navigate between plan items at all
  /// (i.e. it has a non-empty list of items and a valid index).
  bool get hasPlanItems =>
      source == NavigationSource.plan &&
      planTextItems != null &&
      planTextItems!.isNotEmpty &&
      currentTextIndex != null &&
      currentTextIndex! >= 0 &&
      currentTextIndex! < planTextItems!.length;

  /// Check if this navigation context supports swipe navigation
  /// (more than one item to move between).
  bool get canSwipe => hasPlanItems && planTextItems!.length > 1;

  /// Check if there is a next text in the plan
  bool get hasNextText =>
      hasPlanItems && currentTextIndex! < planTextItems!.length - 1;

  /// Check if there is a previous text in the plan
  bool get hasPreviousText => hasPlanItems && currentTextIndex! > 0;

  /// Get the currently selected plan item, if any.
  PlanTextItem? get currentItem =>
      hasPlanItems ? planTextItems![currentTextIndex!] : null;

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

  /// Get the current text item's segment IDs for visibility control
  List<String>? get currentSegmentIds => currentItem?.segmentIds;

  /// Resolve the audio URL for [item], applying precedence: a subtask's own
  /// [PlanTextItem.audioUrl] wins over the shared [dayAudioUrl] fallback.
  /// Returns null when neither is available.
  String? effectiveAudioUrlFor(PlanTextItem item) =>
      item.audioUrl ?? dayAudioUrl;

  /// Whether [item] has any playable audio once precedence is applied.
  bool hasAudioFor(PlanTextItem item) => effectiveAudioUrlFor(item) != null;

  /// The resolved audio URL for the current item, if any.
  String? get currentAudioUrl {
    final item = currentItem;
    return item == null ? null : effectiveAudioUrlFor(item);
  }

  NavigationContext copyWith({
    NavigationSource? source,
    String? planId,
    int? dayNumber,
    String? targetSegmentId,
    List<PlanTextItem>? planTextItems,
    int? currentTextIndex,
    SwipeDirection? navigationDirection,
    bool? autoPlay,
    String? dayAudioUrl,
  }) {
    return NavigationContext(
      source: source ?? this.source,
      planId: planId ?? this.planId,
      dayNumber: dayNumber ?? this.dayNumber,
      targetSegmentId: targetSegmentId ?? this.targetSegmentId,
      planTextItems: planTextItems ?? this.planTextItems,
      currentTextIndex: currentTextIndex ?? this.currentTextIndex,
      navigationDirection: navigationDirection ?? this.navigationDirection,
      autoPlay: autoPlay ?? this.autoPlay,
      dayAudioUrl: dayAudioUrl ?? this.dayAudioUrl,
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
    return 'NavigationContext(source: $source, planId: $planId, dayNumber: $dayNumber, targetSegmentId: $targetSegmentId, currentTextIndex: $currentTextIndex, navigationDirection: $navigationDirection, autoPlay: $autoPlay)';
  }
}
