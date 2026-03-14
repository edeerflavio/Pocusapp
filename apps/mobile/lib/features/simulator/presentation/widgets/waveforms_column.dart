import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ventilator_entities.dart';
import 'waveform_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Theme constants
// ═══════════════════════════════════════════════════════════════════════════

const _green = Color(0xFF4ADE80);
const _cyan = Color(0xFF38BDF8);
const _amber = Color(0xFFFCD34D);
const _borderColor = Color(0x14FFFFFF);

/// Central column: real-time value strip + three stacked waveform channels.
///
/// The value strip at the top shows instantaneous Paw, Flow, and Volume
/// readings. Below, three [WaveformDisplay] widgets render the rolling
/// waveform buffers at compact heights to show 3–5 breath cycles.
class WaveformsColumn extends ConsumerWidget {
  const WaveformsColumn({
    super.key,
    required this.sim,
    required this.peep,
  });

  final SimulationState sim;
  final double peep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read instantaneous values from the last sample.
    final hasData = sim.pressureData.isNotEmpty;
    final idx = sim.currentIndex.clamp(0, hasData ? sim.pressureData.length - 1 : 0);
    final paw = hasData ? sim.pressureData[idx] : peep;
    final flow = hasData ? sim.flowData[idx] : 0.0;
    final vol = hasData ? sim.volumeData[idx] : 0.0;

    return Column(
      children: [
        // ── Real-time value strip ──────────────────────────────────
        _ValueStrip(paw: paw, flow: flow, vol: vol),
        const _WaveDivider(),

        // ── Pressure (Paw) ─────────────────────────────────────────
        Expanded(
          child: WaveformDisplay(
            data: sim.pressureData,
            color: _green,
            label: 'Paw',
            unit: 'cmH₂O',
            minValue: 0,
            maxValue: 50,
            currentIndex: sim.currentIndex,
          ),
        ),
        const _WaveDivider(),

        // ── Flow ───────────────────────────────────────────────────
        Expanded(
          child: WaveformDisplay(
            data: sim.flowData,
            color: _cyan,
            label: 'Flow',
            unit: 'L/min',
            minValue: -60,
            maxValue: 60,
            currentIndex: sim.currentIndex,
          ),
        ),
        const _WaveDivider(),

        // ── Volume ─────────────────────────────────────────────────
        Expanded(
          child: WaveformDisplay(
            data: sim.volumeData,
            color: _amber,
            label: 'Vol',
            unit: 'mL',
            minValue: 0,
            maxValue: 800,
            currentIndex: sim.currentIndex,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Real-time instantaneous values strip
// ═══════════════════════════════════════════════════════════════════════════

class _ValueStrip extends StatelessWidget {
  const _ValueStrip({
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
      color: const Color(0xFF1A2230),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _InstantValue(
            label: 'Paw',
            value: paw.toStringAsFixed(1),
            unit: 'cmH₂O',
            color: _green,
          ),
          _StripDivider(),
          _InstantValue(
            label: 'Flow',
            value: flow.toStringAsFixed(1),
            unit: 'L/min',
            color: _cyan,
          ),
          _StripDivider(),
          _InstantValue(
            label: 'Vol',
            value: vol.toStringAsFixed(0),
            unit: 'mL',
            color: _amber,
          ),
        ],
      ),
    );
  }
}

class _InstantValue extends StatelessWidget {
  const _InstantValue({
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
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: TextStyle(
            color: color.withValues(alpha: 0.3),
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _StripDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _borderColor,
    );
  }
}

class _WaveDivider extends StatelessWidget {
  const _WaveDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: _borderColor);
  }
}
