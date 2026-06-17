import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Default bead artwork bundled with the app, used until/unless the backend
/// supplies a per-mantra bead image on the accumulator.
const String kFallbackBeadAsset = 'assets/beads/bead-1.png';

/// A tappable arc of prayer beads that advances **forward only**.
///
/// The whole region is tappable (`HitTestBehavior.opaque`). Each increment
/// runs one short forward animation — the strand slides one slot along the
/// arc and the apex bead pulses. Because counting is monotonic, the animation
/// never plays in reverse; on a round wrap the [total] keeps growing, so the
/// strand simply keeps sliding forward.
///
/// Beads render the [beadImageUrl] image when present, otherwise the bundled
/// [kFallbackBeadAsset]; a drawn gradient bead shows while the image loads.
class MalaBeads extends StatefulWidget {
  const MalaBeads({
    super.key,
    required this.total,
    required this.beadInRound,
    required this.beadsPerRound,
    required this.onTap,
    required this.beadColor,
    required this.threadColor,
    this.enabled = true,
    this.beadImageUrl,
  });

  /// Absolute lifetime count — drives continuous forward motion (no wrap jump).
  final int total;
  final int beadInRound;
  final int beadsPerRound;
  final VoidCallback onTap;
  final Color beadColor;
  final Color threadColor;
  final bool enabled;
  final String? beadImageUrl;

  @override
  State<MalaBeads> createState() => _MalaBeadsState();
}

class _MalaBeadsState extends State<MalaBeads>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late double _phaseFrom;
  late double _phaseTo;

  ui.Image? _beadImage;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  @override
  void initState() {
    super.initState();
    _phaseFrom = widget.total.toDouble();
    _phaseTo = widget.total.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _resolveBeadImage();
  }

  @override
  void didUpdateWidget(covariant MalaBeads oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.beadImageUrl != oldWidget.beadImageUrl) {
      _resolveBeadImage();
    }
    if (widget.total != oldWidget.total) {
      // Always animate forward from the previously settled phase.
      _phaseFrom = _phaseTo;
      _phaseTo = widget.total.toDouble();
      _controller.forward(from: 0); // never reverse()
    }
  }

  /// Load the network bead image when provided, falling back to the bundled
  /// asset (also used if the network image fails to load).
  void _resolveBeadImage({bool forceAsset = false}) {
    final ImageProvider provider =
        (!forceAsset && (widget.beadImageUrl?.isNotEmpty ?? false))
            ? NetworkImage(widget.beadImageUrl!)
            : const AssetImage(kFallbackBeadAsset);

    final stream = provider.resolve(ImageConfiguration.empty);
    if (stream.key == _imageStream?.key) return;

    _detachImageListener();
    final listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() => _beadImage = info.image);
      },
      onError: (_, __) {
        // Network image failed — fall back to the bundled asset.
        if (!forceAsset) _resolveBeadImage(forceAsset: true);
      },
    );
    _imageStream = stream;
    _imageListener = listener;
    stream.addListener(listener);
  }

  void _detachImageListener() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageListener = null;
  }

  @override
  void dispose() {
    _detachImageListener();
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.enabled) widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final curved = Curves.easeOut.transform(_controller.value);
          final phase = _phaseFrom + (_phaseTo - _phaseFrom) * curved;
          // Pulse the apex bead near the start of the step.
          final pulse =
              (1 - _controller.value) * (_phaseTo - _phaseFrom).clamp(0, 1);
          return CustomPaint(
            size: Size.infinite,
            painter: _MalaBeadsPainter(
              phase: phase,
              pulse: pulse.toDouble(),
              beadColor: widget.beadColor,
              threadColor: widget.threadColor,
              beadImage: _beadImage,
            ),
          );
        },
      ),
    );
  }
}

class _MalaBeadsPainter extends CustomPainter {
  _MalaBeadsPainter({
    required this.phase,
    required this.pulse,
    required this.beadColor,
    required this.threadColor,
    this.beadImage,
  });

  /// Continuous slot position (the absolute count, eased).
  final double phase;

  /// 0..1 emphasis applied to the apex bead right after a tap.
  final double pulse;
  final Color beadColor;
  final Color threadColor;

  /// Bead artwork (network or bundled asset). Null while loading.
  final ui.Image? beadImage;

  /// Beads drawn across the arc (odd, so one sits at the apex).
  static const int _visible = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // A gentle downward arc (a "smile") the beads ride along.
    final p0 = Offset(w * 0.04, h * 0.30);
    final p1 = Offset(w * 0.5, h * 0.95);
    final p2 = Offset(w * 0.96, h * 0.30);

    Offset bezier(double t) {
      final mt = 1 - t;
      final x = mt * mt * p0.dx + 2 * mt * t * p1.dx + t * t * p2.dx;
      final y = mt * mt * p0.dy + 2 * mt * t * p1.dy + t * t * p2.dy;
      return Offset(x, y);
    }

    // Thread.
    final threadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = threadColor.withValues(alpha: 0.6)
      ..strokeCap = StrokeCap.round;
    final threadPath = Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);
    canvas.drawPath(threadPath, threadPaint);

    final frac = phase - phase.floorToDouble(); // continuous slide within a slot
    const apex = _visible ~/ 2;

    // Draw from the edges inward so the apex bead paints on top.
    final order = List<int>.generate(_visible + 2, (i) => i - 1);
    order.sort((a, b) => (b - apex).abs().compareTo((a - apex).abs()));

    for (final i in order) {
      // Slide the whole strand by the fractional phase for continuous motion.
      final slot = i + (1 - frac);
      final t = slot / (_visible - 1);
      if (t < -0.05 || t > 1.05) continue;

      final center = bezier(t.clamp(0.0, 1.0));
      final distFromApex = (slot - apex).abs();
      // Apex beads largest; taper toward the ends.
      final scale = (1.0 - (distFromApex / (_visible)) * 0.55).clamp(0.4, 1.0);
      final isApex = distFromApex < 0.5;
      final radius = (h * 0.16) * scale * (isApex ? 1 + 0.18 * pulse : 1);

      _drawBead(canvas, center, radius, isApex);
    }
  }

  void _drawBead(Canvas canvas, Offset center, double radius, bool isApex) {
    // Drop shadow.
    canvas.drawCircle(
      center.translate(0, radius * 0.18),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final image = beadImage;
    if (image != null) {
      _drawBeadImage(canvas, image, center, radius);
    } else {
      _drawDrawnBead(canvas, center, radius, isApex);
    }

    if (isApex) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  void _drawBeadImage(
    Canvas canvas,
    ui.Image image,
    Offset center,
    double radius,
  ) {
    final dst = Rect.fromCircle(center: center, radius: radius);
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(dst));
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  /// Gradient fallback bead, shown only while the image is loading.
  void _drawDrawnBead(Canvas canvas, Offset center, double radius, bool isApex) {
    final base = isApex ? beadColor : beadColor.withValues(alpha: 0.85);
    final gradient = RadialGradient(
      center: const Alignment(-0.4, -0.5),
      colors: [
        Color.lerp(base, Colors.white, 0.45)!,
        base,
        Color.lerp(base, Colors.black, 0.30)!,
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = gradient.createShader(rect),
    );
    canvas.drawCircle(
      center.translate(-radius * 0.32, -radius * 0.38),
      radius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _MalaBeadsPainter old) =>
      old.phase != phase ||
      old.pulse != pulse ||
      old.beadColor != beadColor ||
      old.threadColor != threadColor ||
      old.beadImage != beadImage;
}
