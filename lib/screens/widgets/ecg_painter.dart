// widgets/ecg_painter.dart
// Draws an animated ECG waveform with PQRST morphology.

import 'dart:math';
import 'package:flutter/material.dart';

class EcgWaveformPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 animation progress
  final Color color;
  final bool isArrest;

  EcgWaveformPainter({
    required this.progress,
    required this.color,
    required this.isArrest,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Glow layer
    final glowPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    final glowPath = Path();
    final w = size.width;
    final h = size.height;
    final mid = h / 2;
    final offset = progress * w;

    // Number of complete beats visible
    const beatWidth = 120.0;
    final totalBeats = (w / beatWidth).ceil() + 1;

    bool started = false;

    for (int beat = 0; beat < totalBeats; beat++) {
      final bx = beat * beatWidth - (offset % beatWidth);

      // Generate one PQRST complex
      final points = isArrest
          ? _vfPoints(bx, mid, h, beat)
          : _pqrstPoints(bx, mid, h);

      for (int i = 0; i < points.length; i++) {
        final p = points[i];
        if (!started) {
          path.moveTo(p.dx, p.dy);
          glowPath.moveTo(p.dx, p.dy);
          started = true;
        } else {
          path.lineTo(p.dx, p.dy);
          glowPath.lineTo(p.dx, p.dy);
        }
      }
    }

    canvas.drawPath(glowPath, glowPaint);
    canvas.drawPath(path, paint);
  }

  /// Normal PQRST complex points
  List<Offset> _pqrstPoints(double bx, double mid, double h) {
    final amp = h * 0.35;
    return [
      Offset(bx, mid),
      Offset(bx + 10, mid),
      // P wave
      Offset(bx + 15, mid - amp * 0.15),
      Offset(bx + 20, mid),
      Offset(bx + 28, mid),
      // Q dip
      Offset(bx + 32, mid + amp * 0.1),
      // R spike
      Offset(bx + 36, mid - amp),
      // S dip
      Offset(bx + 40, mid + amp * 0.2),
      Offset(bx + 45, mid),
      // T wave
      Offset(bx + 55, mid - amp * 0.25),
      Offset(bx + 70, mid),
      Offset(bx + 80, mid),
    ];
  }

  /// VF (chaotic) points for arrest
  List<Offset> _vfPoints(double bx, double mid, double h, int beat) {
    final rng = Random(beat * 1234);
    final amp = h * 0.38;
    final points = <Offset>[];
    for (int i = 0; i < 12; i++) {
      final x = bx + i * 10.0;
      final y = mid + (rng.nextDouble() - 0.5) * amp * 2;
      points.add(Offset(x, y));
    }
    return points;
  }

  @override
  bool shouldRepaint(EcgWaveformPainter old) =>
      old.progress != progress || old.isArrest != isArrest;
}
