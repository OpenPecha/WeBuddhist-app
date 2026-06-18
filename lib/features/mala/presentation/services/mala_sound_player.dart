import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:just_audio/just_audio.dart';

/// Plays a short click on every mala bead count. Loaded once and restarted
/// from the top on each tap so rapid counting stays responsive.
class MalaSoundPlayer {
  MalaSoundPlayer() : _logger = AppLogger('MalaSoundPlayer');

  final AppLogger _logger;
  AudioPlayer? _player;
  bool _isLoaded = false;

  Future<void> init() async {
    try {
      final player = AudioPlayer();
      await player.setAsset(AppAssets.malaSound);
      _player = player;
      _isLoaded = true;
    } catch (e) {
      _logger.warning('Failed to load mala sound: $e');
    }
  }

  void play() {
    final player = _player;
    if (!_isLoaded || player == null) return;

    player.seek(Duration.zero).then((_) => player.play());
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    _isLoaded = false;
  }
}
