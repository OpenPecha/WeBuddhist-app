class AudioState {
  final bool isLoading;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  const AudioState({
    this.isLoading = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  AudioState copyWith({
    bool? isLoading,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? errorMessage,
  }) {
    return AudioState(
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}