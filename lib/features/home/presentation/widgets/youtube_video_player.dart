import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/reusable_youtube_player.dart';

class YoutubeVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;

  const YoutubeVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<YoutubeVideoPlayer> createState() => _YoutubeVideoPlayerState();
}

class _YoutubeVideoPlayerState extends State<YoutubeVideoPlayer> {
  @override
  void initState() {
    super.initState();
    // Hide status bar and navigation bar for a true full-screen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI when leaving the player
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Let the player go behind where the status bar was
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen player ─────────────────────────────────────────
          ReusableYoutubePlayer(
            videoUrl: widget.videoUrl,
            aspectRatio: 9 / 16,
            autoPlay: true,
            mute: false,
            loop: true,
            fillParent: true,
          ),

          // ── Back button overlay ────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(AppAssets.arrowLeft, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
                shape: const CircleBorder(),
              ),
              onPressed: () => context.pop(),
            ),
          ),

          // ── Title overlay at bottom ────────────────────────────────────
          if (widget.title.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
