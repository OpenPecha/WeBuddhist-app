import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/audio_service.dart';
import '../../domain/audio_state.dart';

// 1. Provide a single instance of the AudioService
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

// 2. The Notifier that manages the AudioState
class AudioNotifier extends Notifier<AudioState> {
  late final AudioService _audioService;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  @override
  AudioState build() {
    _audioService = ref.watch(audioServiceProvider);
    _initListeners();
    return const AudioState();
  }

  void _initListeners() {
    _playerStateSub = _audioService.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      
      state = state.copyWith(
        isPlaying: isPlaying,
        isLoading: processingState == ProcessingState.loading || 
                   processingState == ProcessingState.buffering,
      );
    });

    _positionSub = _audioService.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(duration: dur);
    });
  }

  Future<void> playStream(String url, String title) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _audioService.loadAndPlay(url, title: title);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  void togglePlayPause() {
    if (state.isPlaying) {
      _audioService.pause();
    } else {
      _audioService.play();
    }
  }

  void seek(Duration position) {
    _audioService.seek(position);
  }
}

// 3. Expose the Notifier to the UI
final audioProvider = NotifierProvider<AudioNotifier, AudioState>(AudioNotifier.new);