import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../painters/waveform_painter.dart';

/// A single waveform channel display (pressure, flow, or volume).
///
/// Renders the [WaveformPainter] inside a [RepaintBoundary] to isolate
/// canvas repaints from the rest of the widget tree. A label overlay in
/// the top-right corner shows the channel name, unit, and a coloured
/// indicator dot.
///
/// The widget expands to fill whatever height is given by its parent
/// (e.g. an [Expanded] inside a [Column]), making it layout-agnostic.
///
/// ## Usage
/// ```dart
/// WaveformDisplay(
///   data: state.pressureData,
///   color: Color(0xFF00E676),
///   label: 'Paw',
///   unit: 'cmH₂O',
///   minValue: 0,
///   maxValue: 50,
///   currentIndex: state.currentIndex,
/// )
/// ```
class WaveformDisplay extends ConsumerWidget {
  const WaveformDisplay({
    super.key,
    required this.data,
    required this.color,
    required this.label,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.currentIndex,
  });

  /// Waveform samples (up to bufferSize = 1500).
  final List<double> data;

  /// Channel colour for the curve, dot, and label.
  final Color color;

  /// Short channel label (e.g. "Paw", "Flow", "Vol").
  final String label;

  /// Unit string displayed next to the label (e.g. "cmH₂O", "L/min").
  final String unit;

  /// Y-axis minimum (e.g. 0 for pressure, −60 for flow).
  final double minValue;

  /// Y-axis maximum (e.g. 50 for pressure, 800 for volume).
  final double maxValue;

  /// Index of the most recent sample — drives the sweep cursor.
  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // ── Canvas ───────────────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: WaveformPainter(
                data: data,
                color: color,
                min: minValue,
                max: maxValue,
                currentIndex: currentIndex,
              ),
            ),
          ),

          // ── Label overlay (top-right) ────────────────────────────────
          Positioned(
            top: 2,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Coloured indicator dot with glow.
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // Channel label.
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 4),

                // Unit.
                Text(
                  unit,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
