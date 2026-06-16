import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/timer_progress_ring.dart';
import 'package:go_router/go_router.dart';

enum _TimerPhase { countdown, running, finished }

class ActiveTimerScreen extends StatefulWidget {
  const ActiveTimerScreen({super.key, required this.presetTimer});

  final PresetTimer presetTimer;

  @override
  State<ActiveTimerScreen> createState() => _ActiveTimerScreenState();
}

class _ActiveTimerScreenState extends State<ActiveTimerScreen> {
  static const _countdownStart = 5;
  static const _ringSize = 280.0;
  static const _controlsSpacing = 48.0;
  static const _controlsHeight = 56.0;
  static const _centerTextHeight = 48.0;
  static const _durationFontSize = 40.0;

  _TimerPhase _phase = _TimerPhase.countdown;
  int _countdownValue = _countdownStart;
  int _remainingMs = 0;
  bool _isPaused = false;

  Timer? _timer;

  int get _totalMs => widget.presetTimer.durationMs;

  double get _elapsedProgress {
    if (_totalMs <= 0) return 1;
    if (_phase == _TimerPhase.countdown) return 0;
    return ((_totalMs - _remainingMs) / _totalMs).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _remainingMs = _totalMs;
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onCountdownTick(),
    );
  }

  void _onCountdownTick() {
    if (!mounted) return;

    if (_countdownValue <= 1) {
      _timer?.cancel();
      _startMainTimer();
      return;
    }

    setState(() => _countdownValue--);
  }

  void _startMainTimer() {
    setState(() {
      _phase = _TimerPhase.running;
      _remainingMs = _totalMs;
      _isPaused = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onMainTimerTick(),
    );
  }

  void _onMainTimerTick() {
    if (!mounted || _isPaused || _phase != _TimerPhase.running) return;

    setState(() {
      _remainingMs -= 1000;
      if (_remainingMs <= 0) {
        _remainingMs = 0;
        _phase = _TimerPhase.finished;
        _timer?.cancel();
      }
    });
  }

  void _togglePause() {
    if (_phase != _TimerPhase.running && _phase != _TimerPhase.finished) {
      return;
    }
    if (_phase == _TimerPhase.finished) return;

    setState(() => _isPaused = !_isPaused);
  }

  void _finish() {
    _timer?.cancel();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final finishFontSize = textTheme.labelLarge?.fontSize ?? 16.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TimerProgressRing(
                      size: _ringSize,
                      progress: _elapsedProgress,
                      child: _buildCenterContent(textColor),
                    ),
                    const SizedBox(height: _controlsSpacing),
                    SizedBox(
                      height: _controlsHeight,
                      child:
                          _phase != _TimerPhase.countdown
                              ? IconButton(
                                onPressed:
                                    _phase == _TimerPhase.finished
                                        ? null
                                        : _togglePause,
                                iconSize: 40,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: _controlsHeight,
                                  minHeight: _controlsHeight,
                                ),
                                icon: Icon(
                                  _isPaused || _phase == _TimerPhase.finished
                                      ? AppAssets.play
                                      : AppAssets.pause,
                                  color: textColor,
                                ),
                              )
                              : null,
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: _phase != _TimerPhase.countdown,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Center(
                  child: OutlinedButton(
                    onPressed: _finish,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: textColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 46,
                        vertical: 16,
                      ),
                      shape: const StadiumBorder(),
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceWhite,
                    ),
                    child: Text(
                      l10n.timer_finish,
                      strutStyle: context.tibetanStrutStyle(finishFontSize),
                      style: textTheme.labelLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterContent(Color textColor) {
    final textTheme = Theme.of(context).textTheme;
    final text =
        _phase == _TimerPhase.countdown
            ? '$_countdownValue'
            : _formatDuration(_remainingMs);

    return SizedBox(
      height: _centerTextHeight,
      child: Center(
        child: Text(
          text,
          style: textTheme.displaySmall?.copyWith(
            fontSize: _durationFontSize,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: 1,
            color: textColor,
          ),
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    final totalSeconds = (ms / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutesText = minutes.toString().padLeft(2, '0');
    final secondsText = seconds.toString().padLeft(2, '0');
    return '$minutesText : $secondsText';
  }
}
