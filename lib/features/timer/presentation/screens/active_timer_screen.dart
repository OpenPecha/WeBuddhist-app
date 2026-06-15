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
  static const _countdownStart = 3;
  static const _ringSize = 280.0;
  static const _controlsSpacing = 48.0;
  static const _controlsHeight = 56.0;
  static const _bottomBarHeight = 80.0;
  static const _centerTextHeight = 48.0;
  static const _centerTextStyle = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: 1,
  );

  _TimerPhase _phase = _TimerPhase.countdown;
  int _countdownValue = _countdownStart;
  bool _showStartLabel = false;
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onCountdownTick());
  }

  void _onCountdownTick() {
    if (!mounted) return;

    if (_showStartLabel) {
      _timer?.cancel();
      _startMainTimer();
      return;
    }

    if (_countdownValue > 1) {
      setState(() => _countdownValue--);
      return;
    }

    setState(() {
      _countdownValue = 0;
      _showStartLabel = true;
    });
  }

  void _startMainTimer() {
    setState(() {
      _phase = _TimerPhase.running;
      _remainingMs = _totalMs;
      _isPaused = false;
      _showStartLabel = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onMainTimerTick());
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
    final textColor = Theme.of(context).colorScheme.onSurface;

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
                      child: _buildCenterContent(textColor, l10n.timer_start),
                    ),
                    const SizedBox(height: _controlsSpacing),
                    SizedBox(
                      height: _controlsHeight,
                      child: _phase != _TimerPhase.countdown
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
            SizedBox(
              height: _bottomBarHeight,
              child: _phase != _TimerPhase.countdown
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _finish,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              side: BorderSide(color: textColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const StadiumBorder(),
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.surfaceDark
                                      : AppColors.surfaceWhite,
                            ),
                            child: Text(
                              l10n.timer_finish,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterContent(Color textColor, String startLabel) {
    final text =
        _phase == _TimerPhase.countdown
            ? (_showStartLabel ? startLabel : '$_countdownValue')
            : _formatDuration(_remainingMs);

    return SizedBox(
      height: _centerTextHeight,
      child: Center(
        child: Text(
          text,
          style: _centerTextStyle.copyWith(color: textColor),
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
