import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:story_view/story_view.dart';

class ImageStory extends StatefulWidget {
  final String imageUrl;
  final StoryController controller;
  final BoxFit? imageFit;
  final bool roundedTop;
  final bool roundedBottom;

  const ImageStory({
    super.key,
    required this.imageUrl,
    required this.controller,
    this.imageFit,
    this.roundedTop = false,
    this.roundedBottom = false,
  });

  @override
  State<ImageStory> createState() => _ImageStoryState();
}

class _ImageStoryState extends State<ImageStory> {
  @override
  void initState() {
    super.initState();
    widget.controller.pause();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressUp: () {
        widget.controller.play();
      },
      onLongPress: () {
        widget.controller.pause();
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(widget.roundedTop ? 8 : 0),
            bottom: Radius.circular(widget.roundedBottom ? 8 : 0),
          ),
        ),
        child: Stack(
          children: [
            // Image with Hero animation
            Center(
              child: Hero(
                tag: 'verse-image-${widget.imageUrl}',
                child: CachedNetworkImageWidget(
                  imageUrl: widget.imageUrl,
                  fit: widget.imageFit ?? BoxFit.contain,
                  placeholder: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: Builder(
                    builder: (context) {
                      // Resume on error
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        widget.controller.play();
                      });
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Unable to load image',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  onImageLoaded: () {
                    // Resume story progress when image is loaded
                    widget.controller.play();
                  },
                ),
              ),
            ),

            // Play/Pause indicator
            StreamBuilder<PlaybackState>(
              stream: widget.controller.playbackNotifier.stream,
              builder: (context, snapshot) {
                if (snapshot.data == PlaybackState.pause) {
                  return const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white70,
                      size: 64,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
