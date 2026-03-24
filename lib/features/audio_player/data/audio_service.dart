import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  // Expose necessary streams for Riverpod to consume
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> loadAndPlay(
    String url, {
    required String title,
    String? artUrl,
  }) async {
    try {
      await initSession();

      final audioSource = AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: url, // Using URL as a unique ID for simplicity
          album: "WeBuddhist",
          title: title,
          artUri: artUrl != null ? Uri.parse(artUrl) : null,
        ),
      );

      await _player.setAudioSource(audioSource);
      _player.play();
    } catch (e) {
      throw Exception("Failed to load audio: $e");
    }
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration position) => _player.seek(position);

  void dispose() {
    _player.dispose();
  }
}
