import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/simulation_provider.dart';
import '../../application/providers/ventilator_params_provider.dart';
import '../../domain/entities/ventilator_entities.dart';
import '../../domain/enums/ventilation_enums.dart';
import '../widgets/left_panel.dart';
import '../widgets/right_panel.dart';
import '../widgets/ventilator_control_panel.dart';
import '../widgets/waveforms_column.dart';

/// Main simulator screen — assembles the game loop, waveform displays,
/// and control panels into a single dark-themed ICU monitor layout.
///
/// Uses [SingleTickerProviderStateMixin] to drive the simulation at the
/// display refresh rate (~60 fps). The [SimulationNotifier] internally
/// throttles UI state emission to ~20 fps.
class SimulatorScreen extends ConsumerStatefulWidget {
  const SimulatorScreen({super.key});

  @override
  ConsumerState<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends ConsumerState<SimulatorScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  bool _running = true;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!_running) return;
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    ref.read(simulationNotifierProvider.notifier).tick(dt);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final sim = ref.watch(simulationNotifierProvider);
    final params = ref.watch(ventParamsNotifierProvider);
    final modeColor = _modeColor(params.mode);

    return Scaffold(
      backgroundColor: const Color(0xFF121820),
      body: SafeArea(
        child: Column(
          children: [
            // ═══ HEADER BAR ════════════════════════════════════════════
            _HeaderBar(
              sim: sim,
              params: params,
              modeColor: modeColor,
              running: _running,
            ),

            // ═══ MAIN CONTENT ══════════════════════════════════════════
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 700;
                  final isLargeTablet = constraints.maxWidth >= 900;

                  if (isLargeTablet) {
                    // Large tablet: LeftPanel | Waveforms | RightPanel
                    return Row(
                      children: [
                        const SizedBox(width: 220, child: LeftPanel()),
                        Expanded(
                          child: WaveformsColumn(
                            sim: sim, peep: params.peep,
                          ),
                        ),
                        const SizedBox(width: 190, child: RightPanel()),
                      ],
                    );
                  }

                  if (isTablet) {
                    // Medium tablet: ControlPanel | Waveforms
                    return Row(
                      children: [
                        const SizedBox(
                          width: 260,
                          child: VentilatorControlPanel(),
                        ),
                        Expanded(
                          child: WaveformsColumn(
                            sim: sim, peep: params.peep,
                          ),
                        ),
                      ],
                    );
                  }

                  // Phone: waveforms only + bottom FAB to open panel
                  return Stack(
                    children: [
                      WaveformsColumn(sim: sim, peep: params.peep),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'vent_controls',
                          backgroundColor: const Color(0xFF00897B),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: const Color(0xFF1A2230),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              builder: (_) => DraggableScrollableSheet(
                                initialChildSize: 0.7,
                                minChildSize: 0.4,
                                maxChildSize: 0.95,
                                expand: false,
                                builder: (_, controller) =>
                                    const VentilatorControlPanel(),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ═══ FOOTER ════════════════════════════════════════════════
            _FooterBar(
              params: params,
              modeColor: modeColor,
              running: _running,
              onToggleRunning: _toggleRunning,
              onReset: _resetSimulation,
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────

  void _toggleRunning() {
    HapticFeedback.lightImpact();
    setState(() => _running = !_running);
  }

  void _resetSimulation() {
    HapticFeedback.heavyImpact();
    // Stop the ticker BEFORE resetting to avoid a timing glitch where
    // _onTick fires between reset() and _lastElapsed being zeroed.
    _ticker.stop();
    ref.read(simulationNotifierProvider.notifier).reset();
    _lastElapsed = Duration.zero;
    setState(() => _running = true);
    // Restart the ticker — elapsed resets to zero on start().
    _ticker.start();
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  static Color _modeColor(VentMode mode) => switch (mode) {
        VentMode.vcv => const Color(0xFF10B981),
        VentMode.pcv => const Color(0xFF38BDF8),
        VentMode.psv => const Color(0xFFF59E0B),
        VentMode.aprv => const Color(0xFFA78BFA),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// _HeaderBar — top monitor strip with key metrics
// ═══════════════════════════════════════════════════════════════════════════

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.sim,
    required this.params,
    required this.modeColor,
    required this.running,
  });

  final SimulationState sim;
  final VentParams params;
  final Color modeColor;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final m = sim.metrics;
    final dp = m.vte > 0 ? m.vte / params.compliance : params.vt / params.compliance;
    final pplat = params.peep + dp;
    final vtPerKg = m.vte > 0 ? m.vte / 66.0 : params.vt / 66.0; // approx IBW

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2230),
        border: Border(
          bottom: BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Mode badge.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: modeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: modeColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              params.mode.shortLabel,
              style: TextStyle(
                color: modeColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Phase indicator.
          _PhaseChip(phase: sim.phase, modeColor: modeColor),
          const SizedBox(width: 12),

          // Metrics strip.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: params.mode == VentMode.aprv
                    ? [
                        _Metric(label: 'P-high', value: params.pHigh.toStringAsFixed(0), unit: 'cmH₂O', color: const Color(0xFFA78BFA)),
                        _Metric(label: 'P-low', value: params.pLow.toStringAsFixed(0), unit: 'cmH₂O', color: const Color(0xFFA78BFA)),
                        _Metric(label: 'T-high', value: params.tHigh.toStringAsFixed(1), unit: 's', color: const Color(0xFF38BDF8)),
                        _Metric(label: 'T-low', value: params.tLow.toStringAsFixed(1), unit: 's', color: const Color(0xFF38BDF8)),
                        _Metric(label: 'VTe', value: '${m.vte}', unit: 'mL', color: const Color(0xFFF59E0B)),
                        _Metric(label: 'FR', value: '${m.rr}', unit: 'rpm', color: const Color(0xFF38BDF8)),
                        _Metric(label: 'VM', value: m.minuteVolume.toStringAsFixed(1), unit: 'L/min', color: const Color(0xFF38BDF8)),
                        _Metric(label: 'Esp.RR', value: '${params.spontaneousRR}', unit: 'rpm', color: const Color(0xFFA78BFA)),
                      ]
                    : [
                        _Metric(label: 'PIP', value: '${m.pip}', unit: 'cmH₂O', color: const Color(0xFF10B981)),
                        _Metric(label: 'PEEP', value: '${m.peep}', unit: 'cmH₂O', color: const Color(0xFF10B981)),
                        _Metric(label: 'VTe', value: '${m.vte}', unit: 'mL', color: const Color(0xFFF59E0B)),
                        _Metric(label: 'FR', value: '${m.rr}', unit: 'rpm', color: const Color(0xFF38BDF8)),
                        _Metric(label: 'VM', value: m.minuteVolume.toStringAsFixed(1), unit: 'L/min', color: const Color(0xFF38BDF8)),
                        _Metric(label: 'ΔP', value: dp.toStringAsFixed(1), unit: 'cmH₂O', color: dp > 15 ? const Color(0xFFFF6B6B) : const Color(0xFF10B981)),
                        _Metric(label: 'Pplat', value: pplat.toStringAsFixed(0), unit: 'cmH₂O', color: pplat > 30 ? const Color(0xFFFF6B6B) : const Color(0xFF10B981)),
                        _Metric(label: 'VT/kg', value: vtPerKg.toStringAsFixed(1), unit: 'mL/kg', color: vtPerKg > 8 ? const Color(0xFFFF6B6B) : const Color(0xFF10B981)),
                      ],
              ),
            ),
          ),

          // Running indicator.
          if (!running)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'PAUSA',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _FooterBar — bottom bar with preset selector, play/pause, reset
// ═══════════════════════════════════════════════════════════════════════════

class _FooterBar extends StatelessWidget {
  const _FooterBar({
    required this.params,
    required this.modeColor,
    required this.running,
    required this.onToggleRunning,
    required this.onReset,
  });

  final VentParams params;
  final Color modeColor;
  final bool running;
  final VoidCallback onToggleRunning;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final infoText = params.mode == VentMode.aprv
        ? 'APRV P-hi:${params.pHigh.toStringAsFixed(0)} P-lo:${params.pLow.toStringAsFixed(0)}'
        : '${params.mode.shortLabel} PEEP:${params.peep.toStringAsFixed(0)} I:E 1:${params.ieRatio.toStringAsFixed(1)}';

    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2230),
        border: Border(
          top: BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Mode info — shrinks to fit available space.
          Flexible(
            child: Text(
              infoText,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0x8CFFFFFF),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Play / Pause — fixed width, never clipped.
          _FooterButton(
            icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
            label: running ? 'Pausa' : 'Iniciar',
            color: modeColor,
            onTap: onToggleRunning,
          ),
          const SizedBox(width: 6),

          // Reset — fixed width, never clipped.
          _FooterButton(
            icon: Icons.restart_alt_rounded,
            label: 'Reset',
            color: const Color(0xFFFF6B6B),
            onTap: onReset,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Small reusable widgets
// ═══════════════════════════════════════════════════════════════════════════

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.phase, required this.modeColor});

  final BreathPhase phase;
  final Color modeColor;

  @override
  Widget build(BuildContext context) {
    final isInsp = phase == BreathPhase.inspiration;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isInsp ? modeColor : const Color(0xFF607080))
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        isInsp ? 'INSP' : 'EXP',
        style: TextStyle(
          color: isInsp ? modeColor : const Color(0xFF607080),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
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
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              height: 1.1,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: color.withValues(alpha: 0.3),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
