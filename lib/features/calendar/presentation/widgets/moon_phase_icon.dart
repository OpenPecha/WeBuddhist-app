import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/calendar/domain/models/moon_phase.dart';

/// Renders the icon for a [MoonPhase].
///
/// Prefers the branded asset at [MoonPhaseAssets.assetPath] (with a `dark/`
/// variant in dark mode). Until those assets exist the [errorBuilder] falls
/// back to a self-contained painted moon, so the screen looks right today and
/// switches to the real artwork automatically once the files are added to
/// `assets/images/moon/` (and declared in pubspec).
class MoonPhaseIcon extends StatelessWidget {
  const MoonPhaseIcon({super.key, required this.phase, this.size = 58});

  final MoonPhase phase;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Theme-neutral artwork: the same asset is used in both light and dark
    // mode. The painted fallback still adapts to [dark] if an asset is missing.
    return Image.asset(
      phase.assetPath(),
      width: size,
      height: size,
      errorBuilder:
          (context, error, stack) =>
              _PaintedMoon(phase: phase, size: size, dark: dark),
    );
  }
}

class _PaintedMoon extends StatelessWidget {
  const _PaintedMoon({
    required this.phase,
    required this.size,
    required this.dark,
  });

  final MoonPhase phase;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    // Matches the project's chart: the illuminated portion is drawn as ink
    // (dark) on a light disc in light mode, inverted in dark mode.
    final lit = dark ? const Color(0xFFE0E0E0) : const Color(0xFF1C1B1A);
    final unlit = dark ? const Color(0xFF3A3A3A) : const Color(0xFFD9D6CE);
    return CustomPaint(
      size: Size.square(size),
      painter: _MoonPainter(phase: phase, lit: lit, unlit: unlit),
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter({required this.phase, required this.lit, required this.unlit});

  final MoonPhase phase;
  final Color lit;
  final Color unlit;

  /// Representative position in the synodic cycle, 0 (new) .. 0.5 (full) .. 1.
  static double _age(MoonPhase p) {
    switch (p) {
      case MoonPhase.newMoon:
        return 0.0;
      case MoonPhase.waxingCrescent:
        return 0.125;
      case MoonPhase.firstQuarter:
        return 0.25;
      case MoonPhase.waxingGibbous:
        return 0.375;
      case MoonPhase.fullMoon:
        return 0.5;
      case MoonPhase.waningGibbous:
        return 0.625;
      case MoonPhase.lastQuarter:
        return 0.75;
      case MoonPhase.waningCrescent:
        return 0.875;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final age = _age(phase);
    final illum = (1 - math.cos(2 * math.pi * age)) / 2; // 0..1
    final waxing = age <= 0.5;

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    // Illuminated base.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = lit
        ..isAntiAlias = true,
    );
    // Shadow disc carves the unlit lune. Sliding a same-radius disc across the
    // moon gives every phase: centred = new, fully off = full.
    final shadowDx = waxing ? c.dx - 2 * r * illum : c.dx + 2 * r * illum;
    canvas.drawCircle(
      Offset(shadowDx, c.dy),
      r,
      Paint()
        ..color = unlit
        ..isAntiAlias = true,
    );
    canvas.restore();

    // Subtle rim so the disc edge reads even when nearly all unlit.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = lit.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant _MoonPainter old) =>
      old.phase != phase || old.lit != lit || old.unlit != unlit;
}
