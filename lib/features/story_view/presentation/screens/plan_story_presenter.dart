import 'package:flutter/material.dart';
import 'package:flutter_story_presenter/flutter_story_presenter.dart';
import 'package:go_router/go_router.dart';

typedef FlutterStoryItemsBuilder =
    List<StoryItem> Function(FlutterStoryController controller);

class PlanStoryPresenter extends StatefulWidget {
  const PlanStoryPresenter({super.key, required this.storyItemsBuilder});

  final FlutterStoryItemsBuilder storyItemsBuilder;

  @override
  State<PlanStoryPresenter> createState() => _PlanStoryPresenterState();
}

class _PlanStoryPresenterState extends State<PlanStoryPresenter> {
  late final FlutterStoryController flutterStoryController;
  late final List<StoryItem> storyItems;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    flutterStoryController = FlutterStoryController();
    storyItems = widget.storyItemsBuilder(flutterStoryController);
  }

  @override
  void dispose() {
    _isDisposing = true;
    // Let the FlutterStoryPresenter package handle controller disposal
    // The package manages its own controller lifecycle
    super.dispose();
  }

  void _closeStory() {
    if (!mounted || _isDisposing) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposing) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        FlutterStoryPresenter(
          flutterStoryController: flutterStoryController,
          items: storyItems,
          onCompleted: () async {
            if (!_isDisposing && mounted) {
              context.pop();
            }
          },
          onSlideDown: (details) {
            if (!_isDisposing && mounted) {
              context.pop();
            }
          },
        ),
        // if (widget.author != null) StoryAuthorAvatar(author: widget.author),
        // Close button in top-left corner
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _closeStory,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
