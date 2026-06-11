import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigation_bottom_bar.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_subtask_completion.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_bottom_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_button.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

enum _ButtonState { play, loading, pause }

/// Lightweight reading screen for plan subtasks where `content_type == "TEXT"`.
///
/// The subtask `content` is treated as markdown and rendered via
/// [PlanInlineMarkdownView]. Plain text remains valid markdown so callers
/// without formatting need no changes.
///
/// Audio behaviour:
/// - A floating play/pause button appears when the task has an audio segment.
/// - Tapping it plays the task's segment. When the segment ends the screen
///   auto-advances to the next task with auto-play.
/// - Audio stops on any manual navigation or back press — no leaks.
class PlanTextScreen extends ConsumerStatefulWidget {
  final NavigationContext navigationContext;
  const PlanTextScreen({super.key, required this.navigationContext});

  @override
  ConsumerState<PlanTextScreen> createState() => _PlanTextScreenState();
}

class _PlanTextScreenState extends ConsumerState<PlanTextScreen>
    with SingleTickerProviderStateMixin {
  // ─── Navigation state ──────────────────────────────────────────────────
  bool _isNavigating = false;
  double _dragOffset = 0.0;
  bool _isDragging = false;

  // ─── Audio resources ───────────────────────────────────────────────────
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;

  // ─── Audio state ───────────────────────────────────────────────────────
  _ButtonState _buttonState = _ButtonState.play;

  /// Drives the play↔pause icon morph. At 0.0 = play ▶, at 1.0 = pause ⏸.
  late final AnimationController _iconController;

  /// Incremented by [_cancelAudio] so any in-flight [_startAudio] can detect
  /// it has been superseded and abort before calling play().
  int _audioSessionId = 0;

  /// Guards against [_onPosition] triggering auto-advance more than once.
  bool _hasAutoAdvanced = false;

  // ─── Resolved audio window ─────────────────────────────────────────────
  String? _audioUrl;
  int? _startMs;
  int? _endMs;

  bool get _hasAudio => _audioUrl != null;

  // ─── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resolveAudioWindow();
    if (widget.navigationContext.autoPlay && _hasAudio) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAudio());
    }
  }

  void _resolveAudioWindow() {
    final ctx = widget.navigationContext;
    final item = ctx.currentItem;
    if (ctx.dayAudioUrl != null && item != null && item.hasAudioSegment) {
      _audioUrl = ctx.dayAudioUrl;
      _startMs = item.startMs;
      _endMs = item.endMs;
    }
  }

  @override
  void dispose() {
    _cancelAudio();
    _player?.dispose();
    _iconController.dispose();
    super.dispose();
  }

  // ─── Audio control ─────────────────────────────────────────────────────

  /// Load [_audioUrl], seek to [_startMs], and begin playback.
  ///
  /// **Never awaits [play()]** — in just_audio, [play()] only completes when
  /// playback *stops*; awaiting it would block the UI for the full duration.
  ///
  /// **Session guard**: captures [_audioSessionId] at entry. If [_cancelAudio]
  /// is called while this method is suspended on an `await`, it increments the
  /// session id, and the guard aborts before subscribing or calling play —
  /// preventing phantom audio during the page-exit animation.
  Future<void> _startAudio() async {
    if (!_hasAudio || _buttonState == _ButtonState.loading) return;

    final sessionId = ++_audioSessionId;
    setState(() => _buttonState = _ButtonState.loading);

    try {
      _player ??= AudioPlayer();

      // Tear down stale subscriptions before rebinding
      _playerStateSub?.cancel();
      _positionSub?.cancel();
      _playerStateSub = null;
      _positionSub = null;

      await _player!.setUrl(_audioUrl!);
      if (!mounted || sessionId != _audioSessionId) return;

      await _player!.seek(Duration(milliseconds: _startMs ?? 0));
      if (!mounted || sessionId != _audioSessionId) return;

      _hasAutoAdvanced = false;

      // Subscribe *before* play so no events are missed.
      // skip(1) discards the BehaviorSubject's stale initial emit
      // (playing: false, ready) which would otherwise race with
      // the setState(pause) below and incorrectly reset the button.
      _playerStateSub = _player!.playerStateStream
          .skip(1)
          .listen(_onPlayerState);
      _positionSub = _player!.positionStream.listen(_onPosition);

      // Fire-and-forget: play() completes only when playback stops.
      _player!.play();

      if (mounted) {
        setState(() => _buttonState = _ButtonState.pause);
        _iconController.forward();
      }
    } catch (_) {
      // Presigned URL expired, network failure, etc. — reset to idle.
      if (mounted) setState(() => _buttonState = _ButtonState.play);
    }
  }

  /// Handles *unexpected* player stops (network drop, track ends before
  /// [_endMs]). Normal pauses are driven explicitly; this is the safety net.
  ///
  /// The skip(1) on the subscription means the first BehaviorSubject emit
  /// (which is stale) never reaches this handler.
  void _onPlayerState(PlayerState state) {
    if (!mounted || _buttonState != _ButtonState.pause) return;
    if (!state.playing &&
        state.processingState != ProcessingState.loading &&
        state.processingState != ProcessingState.buffering) {
      setState(() => _buttonState = _ButtonState.play);
      _iconController.reverse();
    }
  }

  /// Position stream callback. Triggers auto-advance exactly once when the
  /// segment boundary is reached. [_hasAutoAdvanced] prevents re-entry.
  void _onPosition(Duration position) {
    if (_hasAutoAdvanced) return;
    final end = _endMs;
    if (end == null) return;
    if (position.inMilliseconds >= end) {
      _hasAutoAdvanced = true;
      _autoAdvance();
    }
  }

  Future<void> _togglePlayPause() async {
    switch (_buttonState) {
      case _ButtonState.loading:
        return; // ignore taps while loading

      case _ButtonState.pause:
        await _player?.pause();
        if (mounted) {
          setState(() => _buttonState = _ButtonState.play);
          _iconController.reverse();
        }

      case _ButtonState.play:
        if (_player == null) {
          await _startAudio();
          return;
        }
        final ps = _player!.processingState;
        if (ps == ProcessingState.idle || ps == ProcessingState.completed) {
          // Full restart — URL/seek needed again
          await _startAudio();
          return;
        }
        // Resume within the current segment
        _hasAutoAdvanced = false;
        _positionSub?.cancel();
        _positionSub = _player!.positionStream.listen(_onPosition);
        _player!.play(); // fire-and-forget
        if (mounted) {
          setState(() => _buttonState = _ButtonState.pause);
          _iconController.forward();
        }
    }
  }

  /// Tears down all audio resources synchronously. Safe to call from
  /// [dispose] or navigation handlers. Idempotent.
  ///
  /// Increments [_audioSessionId] so any in-flight [_startAudio] aborts
  /// before it can call [play()] on a session that has been cancelled.
  void _cancelAudio() {
    _audioSessionId++; // invalidate any in-flight _startAudio
    _hasAutoAdvanced = true; // prevent late-firing position callbacks
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub = null;
    _positionSub = null;
    _player?.stop(); // fire-and-forget; dispose() cleans up the player
  }

  /// Called by [_onPosition] when the segment boundary is reached.
  /// Marks the current subtask complete and navigates to the next task
  /// with auto-play. Falls through to [_finish] on the last task.
  void _autoAdvance() {
    if (!mounted || _isNavigating) return;

    _cancelAudio();
    ref
        .read(planSubtaskCompletionProvider)
        .completeCurrent(widget.navigationContext);

    final didNavigate = PlanNavigator.navigateAdjacent(
      context,
      widget.navigationContext,
      SwipeDirection.next,
      autoPlay: true,
    );

    if (didNavigate) {
      setState(() => _isNavigating = true);
    } else {
      _finish(); // no next task — close the sequence
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.navigationContext.currentItem;
    final fontSize = ref.watch(fontSizeProvider);

    if (currentItem == null || currentItem.inlineContent == null) {
      return _buildMissingContentScaffold(context);
    }

    final canSwipe = widget.navigationContext.canSwipe;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, currentItem.title),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: canSwipe ? _onDragStart : null,
        onHorizontalDragUpdate: canSwipe ? _onDragUpdate : null,
        onHorizontalDragEnd: canSwipe ? _onDragEnd : null,
        onHorizontalDragCancel: canSwipe ? _onDragCancel : null,
        child: SafeArea(
          child: AnimatedContainer(
            duration: Duration(milliseconds: _isDragging ? 0 : 250),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_dragOffset * 0.25, 0, 0),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Text content — extra bottom padding reserves visual
                      // space so the last line stays above the floating button.
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          16,
                          20,
                          _hasAudio ? 88 : 16,
                        ),
                        child: PlanInlineMarkdownView(
                          content: currentItem.inlineContent!,
                          fontSize: fontSize,
                        ),
                      ),
                      // Floating play/pause — overlaid, zero layout footprint.
                      if (_hasAudio)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 8,
                          child: Center(child: _buildAudioButton(context)),
                        ),
                    ],
                  ),
                ),
                PlanNavigationBottomBar(
                  navigationContext: widget.navigationContext,
                  fallbackTitle: currentItem.title,
                  onPreviousTap: () => _navigate(SwipeDirection.previous),
                  onNextTap: () => _navigate(SwipeDirection.next),
                  onFinishedTap: _finish,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(AppAssets.arrowLeft),
        onPressed: () {
          _cancelAudio();
          context.pop();
        },
      ),
      centerTitle: true,
      actions: [
        ReaderFontSizeButton(onPressed: () => showFontSizeBottomSheet(context)),
        const SizedBox(width: 12),
      ],
    );
  }

  /// Floating play/pause/loading button with smooth icon morph.
  Widget _buildAudioButton(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final isLoading = _buttonState == _ButtonState.loading;

    return Material(
      color: bgColor.withAlpha(235),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black38,
      child: InkWell(
        onTap: isLoading ? null : _togglePlayPause,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withAlpha(100), width: 1.5),
          ),
          alignment: Alignment.center,
          child:
              isLoading
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: color,
                    ),
                  )
                  : AnimatedIcon(
                    icon: AnimatedIcons.play_pause,
                    progress: _iconController,
                    size: 28,
                    color: color,
                  ),
        ),
      ),
    );
  }

  Widget _buildMissingContentScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(child: Text(context.l10n.no_content)),
    );
  }

  // ─── Drag / swipe ──────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails _) {
    if (_isNavigating) return;
    setState(() {
      _isDragging = true;
      _dragOffset = 0.0;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isNavigating) return;
    setState(() => _dragOffset += details.primaryDelta ?? 0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isNavigating) {
      _resetDrag();
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isHighVelocity =
        velocity.abs() >= ReaderConstants.swipeVelocityThreshold;
    final isFarDrag = _dragOffset.abs() > screenWidth * 0.2;

    if (isHighVelocity || isFarDrag) {
      final goNext = velocity < 0 || (velocity == 0 && _dragOffset < 0);
      _navigate(goNext ? SwipeDirection.next : SwipeDirection.previous);
    }
    _resetDrag();
  }

  void _onDragCancel() => _resetDrag();

  void _resetDrag() {
    setState(() {
      _isDragging = false;
      _dragOffset = 0.0;
    });
  }

  // ─── Navigation ────────────────────────────────────────────────────────

  void _navigate(SwipeDirection direction) {
    if (_isNavigating) return;
    if (direction == SwipeDirection.next) {
      ref
          .read(planSubtaskCompletionProvider)
          .completeCurrent(widget.navigationContext);
    }
    _cancelAudio();
    final didNavigate = PlanNavigator.navigateAdjacent(
      context,
      widget.navigationContext,
      direction,
    );
    if (!didNavigate && direction == SwipeDirection.next) {
      _finish();
      return;
    }
    if (didNavigate) setState(() => _isNavigating = true);
  }

  void _finish() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    _cancelAudio();
    await ref
        .read(planSubtaskCompletionProvider)
        .completeCurrent(widget.navigationContext);
    if (!mounted) return;
    context.pop();
  }
}
