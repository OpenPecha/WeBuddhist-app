import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/audio_controls.dart';
import 'package:flutter_pecha/core/widgets/audio_progress_bar.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/meditation_of_day/domain/entities/meditation.dart';
import 'package:flutter_pecha/features/meditation_of_day/presentation/providers/meditation_notifier.dart';
import 'package:flutter_pecha/features/meditation_of_day/presentation/state/meditation_state.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MeditationOfTheDayScreen extends ConsumerStatefulWidget {
  const MeditationOfTheDayScreen({super.key});

  @override
  ConsumerState<MeditationOfTheDayScreen> createState() =>
      _MeditationOfTheDayScreenState();
}

class _MeditationOfTheDayScreenState extends ConsumerState<MeditationOfTheDayScreen> {
  late AudioPlayer _audioPlayer;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Meditation? _currentMeditation;
  bool _hasInitializedAudio = false;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    // Load meditation data using the new architecture
    Future.microtask(() {
      ref.read(meditationNotifierProvider.notifier).loadTodayMeditation();
    });
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();

      _audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration ?? Duration.zero;
          });
        }
      });

      _audioPlayer.positionStream.listen((pos) {
        if (mounted) {
          setState(() {
            _position = pos;
          });
        }
      });

      // Handle completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          // Reset position when completed
          if (mounted) {
            setState(() {
              _position = Duration.zero;
            });
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to initialize audio player. Please try again later.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadAudioForMeditation(Meditation meditation) async {
    if (_hasInitializedAudio && _currentMeditation?.id == meditation.id) {
      return; // Already loaded this meditation
    }

    try {
      // Try to load from URL if it's a network resource
      if (meditation.audioUrl.startsWith('http')) {
        await _audioPlayer.setUrl(meditation.audioUrl);
      } else {
        // Load from assets
        await _audioPlayer.setAsset(meditation.audioUrl);
      }

      if (mounted) {
        setState(() {
          _currentMeditation = meditation;
          _hasInitializedAudio = true;
        });
      }

      // Auto-play on load
      if (mounted) {
        await _audioPlayer.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to load meditation audio. Please try again later.',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final meditationState = ref.watch(meditationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            _audioPlayer.stop();
            context.pop();
          },
        ),
        title: Text(localizations.home_meditationTitle),
        centerTitle: true,
        elevation: 0,
      ),
      body: meditationState.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (meditation) {
          // Load audio when meditation data is available
          Future.microtask(() => _loadAudioForMeditation(meditation));
          return _buildContent(meditation);
        },
        error: (message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(meditationNotifierProvider.notifier).loadTodayMeditation();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Meditation meditation) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Expanded(
          child: CachedNetworkImageWidget(
            imageUrl: meditation.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // Audio player controls
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 0.0,
            bottom: 16.0,
          ),
          child: Column(
            children: [
              // Progress bar
              AudioProgressBar(
                audioPlayer: _audioPlayer,
                duration: _duration,
                position: _position,
              ),
              // Controls
              AudioControls(
                audioPlayer: _audioPlayer,
                duration: _duration,
                position: _position,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }
}

// Extension for state.when
extension MeditationStateX on MeditationState {
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(Meditation meditation) loaded,
    required T Function(String message) error,
  }) {
    if (this is MeditationInitial) {
      return initial();
    } else if (this is MeditationLoading) {
      return loading();
    } else if (this is MeditationLoaded) {
      return loaded((this as MeditationLoaded).meditation);
    } else {
      return error((this as MeditationError).message);
    }
  }
}
