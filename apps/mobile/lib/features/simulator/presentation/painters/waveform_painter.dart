import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// High-performance custom painter for real-time ventilator waveforms.
///
/// Renders a single waveform channel (pressure, flow, or volume) as a
/// smooth curve over a dark background with ICU-style green grid lines,
/// a sweep cursor, and Y-axis labels.
///
/// ## Performance considerations
///
/// - **Downsampling**: at most 1 data point per horizontal pixel is drawn.
///   With 1500 samples and a ~400 px wide widget, this reduces the path
///   to ~400 segments — well within 16 ms budget at 60 fps.
/// - **RepaintBoundary**: the consuming widget should wrap the
///   [CustomPaint] in a [RepaintBoundary] to isolate repaints from the
///   rest of the widget tree.
/// - **shouldRepaint**: only triggers when [currentIndex] or [data]
///   reference changes.
class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.data,
    required this.color,
    required this.min,
    required this.max,
    required this.currentIndex,
  });

  /// The waveform samples to render (up to [EngineConstants.bufferSize]).
  final List<double> data;

  /// Stroke and glow colour for the waveform curve.
  final Color color;

  /// Y-axis minimum (e.g. −60 for flow, 0 for volume).
  final double min;

  /// Y-axis maximum (e.g. 50 for pressure, 800 for volume).
  final double max;

  /// Index of the most recent sample — drives the sweep cursor.
  final int currentIndex;

  // ── Layout constants ───────────────────────────────────────────────────

  static const _pad = EdgeInsets.fromLTRB(3, 4, 3, 8);
  static const _bgColor = Color(0xF9121820);
  static const _gridColor = Color(0x0AFFFFFF);
  static const _vGridColor = Color(0x09FFFFFF);
  static const _zeroLineColor = Color(0x12FFFFFF);
  static const _cursorLineColor = Color(0x0DFFFFFF);
  static const _labelColor = Color(0x2EFFFFFF);

  /// Approximate samples per second (engine runs at 250 Hz).
  static const _samplesPerSec = 250;

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Dark background ─────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _bgColor,
    );

    final plotW = size.width - _pad.left - _pad.right;
    final plotH = size.height - _pad.top - _pad.bottom;
    final range = (max - min).clamp(0.001, double.infinity);

    // ── 2. Horizontal grid (3 divisions) ───────────────────────────────
    final gridPaint = Paint()
      ..color = _gridColor
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 3; i++) {
      final y = _pad.top + (plotH * i) / 3;
      canvas.drawLine(
        Offset(_pad.left, y),
        Offset(size.width - _pad.right, y),
        gridPaint,
      );
    }

    // ── 3. Vertical grid (~1 s intervals) ──────────────────────────────
    final vGridPaint = Paint()
      ..color = _vGridColor
      ..strokeWidth = 0.5;
    for (int s = _samplesPerSec; s < data.length; s += _samplesPerSec) {
      final x = _pad.left + (plotW * s) / (data.length - 1);
      canvas.drawLine(
        Offset(x, _pad.top),
        Offset(x, _pad.top + plotH),
        vGridPaint,
      );
    }

    // ── 4. Zero line for flow (when range spans negative values) ───────
    if (min < 0) {
      final zeroY = _pad.top + plotH * (max / range);
      final zeroPaint = Paint()
        ..color = _zeroLineColor
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(_pad.left, zeroY),
        Offset(size.width - _pad.right, zeroY),
        zeroPaint,
      );
    }

    // ── 5. Waveform curve — downsampled to max 1 point per pixel ───────
    if (data.length > 1) {
      final maxPx = plotW.ceil();
      final step = data.length > maxPx ? data.length / maxPx : 1.0;
      final len = data.length;
      final lenM1 = (len - 1).toDouble();

      final path = Path();
      final wavePaint = Paint()
        ..color = color
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 2);

      bool first = true;
      for (double fi = 0; fi < len; fi += step) {
        final i = fi.floor().clamp(0, len - 1);
        final x = _pad.left + (plotW * i) / lenM1;
        final v = data[i].clamp(min, max);
        final y = _pad.top + plotH * (1.0 - (v - min) / range);
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, wavePaint);

      // ── 6. Sweep cursor ────────────────────────────────────────────
      if (currentIndex >= 0 && currentIndex < len) {
        final cx = _pad.left + (plotW * currentIndex) / lenM1;
        final cv = data[currentIndex].clamp(min, max);
        final cy = _pad.top + plotH * (1.0 - (cv - min) / range);

        // Vertical guide line.
        canvas.drawLine(
          Offset(cx, _pad.top),
          Offset(cx, _pad.top + plotH),
          Paint()
            ..color = _cursorLineColor
            ..strokeWidth = 1,
        );

        // Dot with glow.
        canvas.drawCircle(
          Offset(cx, cy),
          2.5,
          Paint()
            ..color = color
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(cx, cy),
          2,
          Paint()..color = color,
        );
      }
    }

    // ── 7. Y-axis labels (min / max) ───────────────────────────────────
    _drawLabel(
      canvas,
      max.toStringAsFixed(0),
      Offset(_pad.left + 2, _pad.top + 2),
    );
    _drawLabel(
      canvas,
      min.toStringAsFixed(0),
      Offset(_pad.left + 2, _pad.top + plotH - 10),
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: _labelColor,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(WaveformPainter old) =>
      old.currentIndex != currentIndex || !identical(old.data, data);
}
