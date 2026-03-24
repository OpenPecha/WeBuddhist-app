import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/utils/duration_extension.dart';
import 'package:flutter_pecha/features/audio_player/domain/audio_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_provider.dart';

class GlobalAudioPlayer extends ConsumerWidget {
  final String audioUrl;
  final String trackTitle;

  const GlobalAudioPlayer({
    super.key,
    required this.audioUrl,
    required this.trackTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);

    // Small text style for the timestamps
    final timeStyle = TextStyle(fontSize: 12, color: Colors.grey.shade600);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          // Play/Pause/Loading Button
          IconButton(
            iconSize: 42,
            icon: _buildIcon(audioState),
            color: Theme.of(context).primaryColor,
            onPressed: () {
              if (audioState.duration == Duration.zero &&
                  !audioState.isLoading) {
                audioNotifier.playStream(audioUrl, trackTitle);
              } else {
                audioNotifier.togglePlayPause();
              }
            },
          ),
          const SizedBox(width: 8),

          // Title, Slider, and Timestamps
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    trackTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Timestamp & Slider Row
                Row(
                  children: [
                    // Current Position
                    Text(
                      audioState.position.toFormattedString(),
                      style: timeStyle,
                    ),

                    // The Slider
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                        ),
                        child: Slider(
                          min: 0.0,
                          max:
                              audioState.duration.inMilliseconds.toDouble() > 0
                                  ? audioState.duration.inMilliseconds
                                      .toDouble()
                                  : 1.0,
                          value: (audioState.position.inMilliseconds.toDouble())
                              .clamp(
                                0.0,
                                audioState.duration.inMilliseconds.toDouble() >
                                        0
                                    ? audioState.duration.inMilliseconds
                                        .toDouble()
                                    : 1.0,
                              ),
                          onChanged: (value) {
                            audioNotifier.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        ),
                      ),
                    ),

                    // Total Duration
                    Text(
                      audioState.duration.toFormattedString(),
                      style: timeStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(AudioState state) {
    if (state.isLoading) {
      return const SizedBox(
        width: 42,
        height: 42,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    } else if (state.isPlaying) {
      return const Icon(Icons.pause_circle_filled);
    } else {
      return const Icon(Icons.play_circle_filled);
    }
  }
}
