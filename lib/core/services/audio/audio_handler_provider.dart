import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/main.dart';
import 'package:flutter_pecha/core/services/audio/audio_handler.dart';

/// Provider for the global audio handler
final audioHandlerProvider = Provider<AppAudioHandler>((ref) {
  return audioHandler as AppAudioHandler;
});
