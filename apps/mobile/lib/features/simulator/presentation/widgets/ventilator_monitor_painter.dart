import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/simulation_provider.dart';
import '../../application/providers/ventilator_params_provider.dart';
// ═══════════════════════════════════════════════════════════════════════════
// VentilatorMonitorPainter — ICU-style three-channel waveform renderer
// ═══════════════════════════════════════════════════════════════════════════

/// High-performance [CustomPainter] that draws three classic ICU ventilator
/// waveforms (Pressure, Flow, Volume) in a single paint pass.
///
/// ## Features
///
/// - **Fading tail**: samples behind the sweep cursor progressively fade
///   to black, mimicking the phosphor decay of classic CRT monitors.
/// - **Downsampling**: at most 1 data point per horizontal pixel per
///   channel — keeps path complexity proportional to widget width.
/// - **Glow effect**: [MaskFilter.blur] on the main stroke gives each
///   waveform a subtle neon glow.
/// - **ICU aesthetic**: black background, dim green grid, per-channel
///   colour coding, monospace labels.
///
/// ## Colour scheme
///
/// | Channel  | Colour        |
/// |----------|---------------|
/// | Pressure | Teal (#00E5CC)|
/// | Flow     | Gold (#FFD740)|
/// | Volume   | White (#E0E0E0)|
///
/// ## Performance notes
///
/// The consuming widget **must** wrap [CustomPaint] in a [RepaintBoundary]
/// to isolate this painter's ~20 fps repaints from the rest of the tree.
/// [shouldRepaint] compares [currentIndex] and data list identity, so
/// unchanged frames are free.
class VentilatorMonitorPainter extends CustomPainter {
  VentilatorMonitorPainter({
    required this.pressureData,
    required this.flowData,
    required this.volumeData,
    required this.currentIndex,
  });

  /// Pressure waveform samples (Paw, cmH₂O).
  final List<double> pressureData;

  /// Flow waveform samples (L/min).
  final List<double> flowData;

  /// Volume waveform samples (mL).
  final List<double> volumeData;

  /// Index of the most recent sample — drives the sweep cursor and fade.
  final int currentIndex;

  // ── Colour palette ─────────────────────────────────────────────────────

  static const _pressureColor = Color(0xFF00E5CC); // Teal
  static const _flowColor = Color(0xFFFFD740); // Gold
  static const _volumeColor = Color(0xFFE0E0E0); // White

  // ── Layout ─────────────────────────────────────────────────────────────

  static const _bgColor = Color(0xFF060A10);
  static const _gridColor = Color(0x0A00FF88);
  static const _zeroLineColor = Color(0x1200FF88);
  static const _dividerColor = Color(0x1A00FF88);
  static const _labelColor = Color(0x40FFFFFF);
  static const _cursorColor = Color(0x18FFFFFF);

  /// Horizontal padding for the plot area.
  static const _padL = 3.0;
  static const _padR = 3.0;
  static const _padTop = 2.0;
  static const _padBot = 2.0;

  /// Vertical gap between channels.
  static const _channelGap = 1.0;

  /// Approximate engine sample rate (Hz).
  static const _samplesPerSec = 250;

  /// Number of samples behind the cursor over which the fade occurs.
  /// ~1.2 seconds of trail at 250 Hz.
  static const _fadeSamples = 300;

  // ── Channel definitions ────────────────────────────────────────────────

  static const _channels = [
    _ChannelDef(
      color: _pressureColor,
      label: 'Paw',
      unit: 'cmH₂O',
      min: 0,
      max: 50,
    ),
    _ChannelDef(
      color: _flowColor,
      label: 'Flow',
      unit: 'L/min',
      min: -60,
      max: 60,
    ),
    _ChannelDef(
      color: _volumeColor,
      label: 'Vol',
      unit: 'mL',
      min: 0,
      max: 800,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Full black background ───────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _bgColor,
    );

    // ── 2. Compute per-channel plot rectangles ─────────────────────────
    final totalGap = _channelGap * 2; // 3 channels → 2 gaps
    final channelH =
        (size.height - _padTop - _padBot - totalGap) / 3;
    final plotW = size.width - _padL - _padR;

    final dataSets = [pressureData, flowData, volumeData];

    for (int ch = 0; ch < 3; ch++) {
      final top = _padTop + ch * (channelH + _channelGap);
      final rect = Rect.fromLTWH(_padL, top, plotW, channelH);
      final def = _channels[ch];
      final data = dataSets[ch];

      _paintChannel(canvas, rect, def, data);

      // Horizontal divider between channels.
      if (ch < 2) {
        canvas.drawLine(
          Offset(0, top + channelH + _channelGap / 2),
          Offset(size.width, top + channelH + _channelGap / 2),
          Paint()
            ..color = _dividerColor
            ..strokeWidth = 0.5,
        );
      }
    }

    // ── 3. Sweep cursor (full height) ──────────────────────────────────
    if (pressureData.isNotEmpty &&
        currentIndex >= 0 &&
        currentIndex < pressureData.length) {
      final len = pressureData.length;
      final cx = _padL + (plotW * currentIndex) / (len - 1).clamp(1, len);

      canvas.drawLine(
        Offset(cx, 0),
        Offset(cx, size.height),
        Paint()
          ..color = _cursorColor
          ..strokeWidth = 1,
      );
    }
  }

  // ── Paint a single channel ─────────────────────────────────────────────

  void _paintChannel(
    Canvas canvas,
    Rect rect,
    _ChannelDef def,
    List<double> data,
  ) {
    final range = (def.max - def.min).clamp(0.001, double.infinity);

    // ── Grid: 3 horizontal divisions ──────────────────────────────────
    final gridPaint = Paint()
      ..color = _gridColor
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 3; i++) {
      final y = rect.top + (rect.height * i) / 3;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }

    // ── Vertical grid (~1 s intervals) ────────────────────────────────
    if (data.isNotEmpty) {
      for (int s = _samplesPerSec; s < data.length; s += _samplesPerSec) {
        final x = rect.left + (rect.width * s) / (data.length - 1);
        canvas.drawLine(
          Offset(x, rect.top),
          Offset(x, rect.bottom),
          gridPaint,
        );
      }
    }

    // ── Zero line (for flow channel with negative range) ──────────────
    if (def.min < 0) {
      final zeroY = rect.top + rect.height * (def.max / range);
      canvas.drawLine(
        Offset(rect.left, zeroY),
        Offset(rect.right, zeroY),
        Paint()
          ..color = _zeroLineColor
          ..strokeWidth = 0.6
          ..style = PaintingStyle.stroke,
      );
    }

    // ── Waveform curve with fading tail ───────────────────────────────
    if (data.length > 1) {
      _paintWaveformWithFade(canvas, rect, def, data);
    }

    // ── Labels (channel name + unit, top-right; min/max, left) ────────
    _drawLabel(
      canvas,
      def.max.toStringAsFixed(0),
      Offset(rect.left + 2, rect.top + 1),
    );
    _drawLabel(
      canvas,
      def.min.toStringAsFixed(0),
      Offset(rect.left + 2, rect.bottom - 10),
    );
    _drawChannelLabel(canvas, rect, def);
  }

  // ── Fading-tail waveform rendering ─────────────────────────────────────

  /// Draws the waveform as multiple short path segments, each with
  /// decreasing opacity behind the sweep cursor, creating a CRT-style
  /// phosphor decay / fading tail effect.
  ///
  /// The curve ahead of the cursor (older data that hasn't been
  /// overwritten) is drawn at very low opacity. The region just behind
  /// the cursor glows at full brightness, fading to ~5 % over
  /// [_fadeSamples] samples.
  void _paintWaveformWithFade(
    Canvas canvas,
    Rect rect,
    _ChannelDef def,
    List<double> data,
  ) {
    final len = data.length;
    final lenM1 = (len - 1).toDouble();
    final range = (def.max - def.min).clamp(0.001, double.infinity);
    final maxPx = rect.width.ceil();
    final step = len > maxPx ? len / maxPx : 1.0;

    // The cursor position — samples at and just before this are brightest.
    final cursor = currentIndex.clamp(0, len - 1);

    // Pre-compute x/y for each downsampled point.
    final points = <Offset>[];
    final indices = <int>[];
    for (double fi = 0; fi < len; fi += step) {
      final i = fi.floor().clamp(0, len - 1);
      final x = rect.left + (rect.width * i) / lenM1;
      final v = data[i].clamp(def.min, def.max);
      final y = rect.top + rect.height * (1.0 - (v - def.min) / range);
      points.add(Offset(x, y));
      indices.add(i);
    }

    if (points.length < 2) return;

    // We split the drawing into small segments of similar opacity to
    // avoid creating one path-per-pixel (expensive) while still giving
    // a smooth fade. ~20 opacity buckets is a good balance.
    const buckets = 20;
    final segmentSize = math.max(1, (points.length / buckets).ceil());

    for (int b = 0; b < buckets; b++) {
      final start = b * segmentSize;
      final end = math.min((b + 1) * segmentSize + 1, points.length);
      if (start >= points.length) break;

      // Compute opacity for the midpoint of this segment.
      final midIdx = indices[math.min(start + segmentSize ~/ 2, indices.length - 1)];
      final alpha = _alphaForIndex(midIdx, cursor, len);

      if (alpha < 0.02) continue; // Skip invisible segments.

      final path = Path()..moveTo(points[start].dx, points[start].dy);
      for (int p = start + 1; p < end; p++) {
        path.lineTo(points[p].dx, points[p].dy);
      }

      final paint = Paint()
        ..color = def.color.withValues(alpha: alpha)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      // Glow only for bright segments.
      if (alpha > 0.4) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.outer, 2);
      }

      canvas.drawPath(path, paint);
    }

    // ── Cursor dot with glow ─────────────────────────────────────────
    if (cursor >= 0 && cursor < len) {
      final cx = rect.left + (rect.width * cursor) / lenM1;
      final cv = data[cursor].clamp(def.min, def.max);
      final cy = rect.top + rect.height * (1.0 - (cv - def.min) / range);

      canvas.drawCircle(
        Offset(cx, cy),
        2.5,
        Paint()
          ..color = def.color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        2,
        Paint()..color = def.color,
      );
    }
  }

  /// Compute the alpha (opacity) for a sample at [index] relative to
  /// the sweep [cursor] position in a buffer of [length] samples.
  ///
  /// - Samples at the cursor: 1.0 (full brightness).
  /// - Samples trailing the cursor within [_fadeSamples]: linear decay
  ///   from 1.0 → 0.05.
  /// - Older samples beyond the fade window: 0.05 (ghost trace).
  /// - Samples ahead of the cursor (not yet overwritten): 0.03.
  double _alphaForIndex(int index, int cursor, int length) {
    if (index == cursor) return 1.0;

    // "Distance behind" the cursor (wrapping around the buffer).
    final behind = (cursor - index) % length;
    final ahead = (index - cursor) % length;

    // If the sample is ahead of the cursor, it's old un-refreshed data.
    if (ahead < behind) return 0.03;

    // Behind the cursor: fade trail.
    if (behind <= _fadeSamples) {
      // Linear fade: 1.0 at cursor → 0.05 at _fadeSamples behind.
      return 1.0 - (behind / _fadeSamples) * 0.95;
    }

    // Beyond fade window: ghost trace.
    return 0.05;
  }

  // ── Text helpers ───────────────────────────────────────────────────────

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: _labelColor,
          fontSize: 8,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  void _drawChannelLabel(Canvas canvas, Rect rect, _ChannelDef def) {
    // Label: "Paw cmH₂O" at top-right of the channel.
    final labelTp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: def.label,
            style: TextStyle(
              color: def.color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          TextSpan(
            text: '  ${def.unit}',
            style: TextStyle(
              color: def.color.withValues(alpha: 0.35),
              fontSize: 8,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    // Dot indicator.
    canvas.drawCircle(
      Offset(rect.right - labelTp.width - 14, rect.top + 8),
      3,
      Paint()
        ..color = def.color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      Offset(rect.right - labelTp.width - 14, rect.top + 8),
      2.5,
      Paint()..color = def.color,
    );

    labelTp.paint(
      canvas,
      Offset(rect.right - labelTp.width - 4, rect.top + 2),
    );
  }

  @override
  bool shouldRepaint(VentilatorMonitorPainter old) =>
      old.currentIndex != currentIndex ||
      !identical(old.pressureData, pressureData) ||
      !identical(old.flowData, flowData) ||
      !identical(old.volumeData, volumeData);
}

// ═══════════════════════════════════════════════════════════════════════════
// _ChannelDef — static channel configuration
// ═══════════════════════════════════════════════════════════════════════════

class _ChannelDef {
  const _ChannelDef({
    required this.color,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
  });

  final Color color;
  final String label;
  final String unit;
  final double min;
  final double max;
}

// ═══════════════════════════════════════════════════════════════════════════
// VentilatorMonitor — widget that wires providers to the painter
// ═══════════════════════════════════════════════════════════════════════════

/// Full ICU-style ventilator monitor widget.
///
/// Reads simulation data from [simulationNotifierProvider] and ventilator
/// parameters from [ventParamsNotifierProvider], then renders all three
/// waveform channels via [VentilatorMonitorPainter] in a single
/// [CustomPaint] wrapped in a [RepaintBoundary].
///
/// Also displays a real-time value strip at the top with instantaneous
/// Paw, Flow, and Volume readings.
///
/// ## Usage
/// ```dart
/// // Inside the simulator screen layout:
/// Expanded(child: VentilatorMonitor())
/// ```
class VentilatorMonitor extends ConsumerWidget {
  const VentilatorMonitor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sim = ref.watch(simulationNotifierProvider);
    final params = ref.watch(ventParamsNotifierProvider);

    // Instantaneous values for the value strip.
    final hasData = sim.pressureData.isNotEmpty;
    final idx =
        sim.currentIndex.clamp(0, hasData ? sim.pressureData.length - 1 : 0);
    final paw = hasData ? sim.pressureData[idx] : params.peep;
    final flow = hasData ? sim.flowData[idx] : 0.0;
    final vol = hasData ? sim.volumeData[idx] : 0.0;

    return Column(
      children: [
        // ── Value strip ────────────────────────────────────────────────
        _MonitorValueStrip(paw: paw, flow: flow, vol: vol),

        // ── Divider ────────────────────────────────────────────────────
        Container(height: 1, color: const Color(0x1A00FF88)),

        // ── Waveform canvas ────────────────────────────────────────────
        Expanded(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: VentilatorMonitorPainter(
                pressureData: sim.pressureData,
                flowData: sim.flowData,
                volumeData: sim.volumeData,
                currentIndex: sim.currentIndex,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _MonitorValueStrip — real-time instantaneous readings
// ═══════════════════════════════════════════════════════════════════════════

class _MonitorValueStrip extends StatelessWidget {
  const _MonitorValueStrip({
    required this.paw,
    required this.flow,
    required this.vol,
  });

  final double paw;
  final double flow;
  final double vol;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      color: const Color(0xFF060A10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MonitorValue(
            label: 'Paw',
            value: paw.toStringAsFixed(1),
            unit: 'cmH₂O',
            color: VentilatorMonitorPainter._pressureColor,
          ),
          _MonitorDivider(),
          _MonitorValue(
            label: 'Flow',
            value: flow.toStringAsFixed(1),
            unit: 'L/min',
            color: VentilatorMonitorPainter._flowColor,
          ),
          _MonitorDivider(),
          _MonitorValue(
            label: 'Vol',
            value: vol.toStringAsFixed(0),
            unit: 'mL',
            color: VentilatorMonitorPainter._volumeColor,
          ),
        ],
      ),
    );
  }
}

class _MonitorValue extends StatelessWidget {
  const _MonitorValue({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 8,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: TextStyle(
            color: color.withValues(alpha: 0.3),
            fontSize: 7,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _MonitorDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0x1A00FF88),
    );
  }
}
