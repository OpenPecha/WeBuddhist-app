import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ReusableYoutubePlayer extends StatefulWidget {
  final String videoUrl;
  final double aspectRatio;
  final bool autoPlay;
  final bool mute;
  final bool loop;

  /// When true, the player expands to fill its parent instead of being
  /// constrained by [aspectRatio]. Use this for true full-screen layouts.
  final bool fillParent;
  final VoidCallback? onReady;
  final ValueChanged<bool>? onStateChanged;
  final ValueChanged<YoutubePlayerController>? onControllerCreated;

  const ReusableYoutubePlayer({
    super.key,
    required this.videoUrl,
    this.aspectRatio = 16 / 9,
    this.autoPlay = false,
    this.mute = false,
    this.loop = false,
    this.fillParent = false,
    this.onReady,
    this.onStateChanged,
    this.onControllerCreated,
  });

  @override
  State<ReusableYoutubePlayer> createState() => _ReusableYoutubePlayerState();
}

class _ReusableYoutubePlayerState extends State<ReusableYoutubePlayer> {
  late YoutubePlayerController _controller;
  bool _hasCalledOnReady = false;
  bool? _previousIsPlaying;
  bool _isDisposed = false;
  // Prevents more than one seekTo callback from being queued at a time
  // when the video reaches the end in loop mode.
  bool _seekPending = false;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: YoutubePlayerFlags(
        autoPlay: widget.autoPlay,
        mute: widget.mute,
        loop: widget.loop,
        hideControls: true,
        controlsVisibleAtStart: false,
        useHybridComposition: true,
        enableCaption: false,
      ),
    );

    // Notify parent widget about controller creation
    if (widget.onControllerCreated != null) {
      widget.onControllerCreated!(_controller);
    }

    // Listen to player state changes
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (_isDisposed || !mounted) return;

    // Handle onReady callback
    if (_controller.value.isReady &&
        !_hasCalledOnReady &&
        widget.onReady != null) {
      _hasCalledOnReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          widget.onReady!();
        }
      });
    }

    // Safety-net loop: restart from the beginning when the video ends.
    // The _seekPending flag ensures only one callback is ever queued per
    // ended-state notification so rapid listener firings don't stack up.
    if (widget.loop &&
        _controller.value.isReady &&
        _controller.value.playerState == PlayerState.ended &&
        !_seekPending) {
      _seekPending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _seekPending = false;
        if (mounted && !_isDisposed) {
          _controller.seekTo(Duration.zero);
          _controller.play();
        }
      });
    }

    // Handle state change callback
    if (widget.onStateChanged != null && _controller.value.isReady) {
      final currentState = _controller.value.playerState;
      final isPlaying = currentState == PlayerState.playing;
      if (isPlaying != _previousIsPlaying) {
        _previousIsPlaying = isPlaying;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposed) {
            widget.onStateChanged!(isPlaying);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.removeListener(_onControllerUpdate);
    // Pause video before disposing to stop WebView activity
    try {
      _controller.pause();
    } catch (_) {
      // Ignore errors if controller is already in bad state
    }
    // Wrap dispose in try-catch to handle InAppWebView disposal race condition
    try {
      _controller.dispose();
    } catch (_) {
      // Ignore disposal errors from InAppWebView race condition
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return const SizedBox.shrink();

    if (widget.fillParent) {
      // YoutubePlayer's internal AspectRatio widget will always pick the
      // largest size satisfying its ratio within the given constraints.
      // To truly fill any screen (e.g. 9:19.5), we measure the available
      // space via LayoutBuilder and feed that exact ratio back to the player,
      // so AspectRatio resolves to the full bounds.
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenRatio = constraints.maxWidth / constraints.maxHeight;
          return YoutubePlayer(
            controller: _controller,
            aspectRatio: screenRatio,
            showVideoProgressIndicator: false,
          );
        },
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: YoutubePlayer(
        controller: _controller,
        aspectRatio: widget.aspectRatio,
        showVideoProgressIndicator: false,
      ),
    );
  }
}
