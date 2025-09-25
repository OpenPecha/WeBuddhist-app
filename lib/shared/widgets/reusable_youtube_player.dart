import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ReusableYoutubePlayer extends StatefulWidget {
  final String videoUrl;
  final double aspectRatio;
  final bool autoPlay;
  final bool mute;
  final bool showVideoProgressIndicator;
  final Color progressIndicatorColor;
  final ProgressBarColors? progressColors;
  final VoidCallback? onReady;

  const ReusableYoutubePlayer({
    super.key,
    required this.videoUrl,
    this.aspectRatio = 16 / 9,
    this.autoPlay = false,
    this.mute = false,
    this.showVideoProgressIndicator = true,
    this.progressIndicatorColor = Colors.red,
    this.progressColors = const ProgressBarColors(
      playedColor: Colors.red,
      handleColor: Colors.redAccent,
    ),
    this.onReady,
  });

  @override
  State<ReusableYoutubePlayer> createState() => _ReusableYoutubePlayerState();
}

class _ReusableYoutubePlayerState extends State<ReusableYoutubePlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: YoutubePlayerFlags(autoPlay: widget.autoPlay, mute: widget.mute),
    );

    if (widget.onReady != null) {
      _controller.addListener(_onControllerUpdate);
    }
  }

  void _onControllerUpdate() {
    if (_controller.value.isReady && widget.onReady != null) {
      widget.onReady!();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        aspectRatio: widget.aspectRatio,
        controller: _controller,
        showVideoProgressIndicator: widget.showVideoProgressIndicator,
        progressIndicatorColor: widget.progressIndicatorColor,
        progressColors: widget.progressColors,
        onReady: widget.onReady,
      ),
      builder: (context, player) {
        return player;
      },
    );
  }
}
