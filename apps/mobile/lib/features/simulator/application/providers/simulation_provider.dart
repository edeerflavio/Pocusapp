import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/ventilator_entities.dart';
import '../../domain/enums/ventilation_enums.dart';
import '../../domain/services/cycle_tracker.dart';
import '../../domain/services/pathophysiology/pathophysiology_modifier.dart';
import '../../domain/services/ventilator_engine.dart';
import 'blood_gas_lab_provider.dart';
import 'pathophysiology_provider.dart';
import 'ventilator_params_provider.dart';

part 'simulation_provider.g.dart';

// ---------------------------------------------------------------------------
// SimulationNotifier — the ventilator simulator game loop.
//
// Driven by a Ticker in the presentation layer (~60 fps). Each tick:
//   1. Advances the engine at 250 Hz (EngineConstants.dt = 4 ms steps).
//   2. Writes samples into high-performance Float64List circular buffers.
//   3. Throttles UI state emission to ~20 fps (every 3rd frame) to keep
//      the widget tree responsive without drowning it in rebuilds.
//
// The separation between engine rate (250 Hz) and render rate (~20 fps)
// ensures physiologically accurate waveforms while maintaining smooth
// 60 fps scrolling and interaction on mobile devices.
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class SimulationNotifier extends _$SimulationNotifier {
  // ── Circular buffers (typed arrays for cache-friendly performance) ────

  late Float64List _pressureBuf;
  late Float64List _flowBuf;
  late Float64List _volumeBuf;

  /// Total number of samples written since the last reset.
  int _writeIndex = 0;

  /// Continuous simulation clock (seconds). Never resets to zero within
  /// a session — the engine uses modular arithmetic internally.
  double _simTime = 0;

  /// Tracks breath boundaries and computes per-cycle metrics.
  late CycleTracker _cycleTracker;

  /// Frame counter used to throttle UI updates to every 3rd frame.
  int _frameCount = 0;

  @override
  SimulationState build() {
    _pressureBuf = Float64List(EngineConstants.bufferSize);
    _flowBuf = Float64List(EngineConstants.bufferSize);
    _volumeBuf = Float64List(EngineConstants.bufferSize);

    final params = ref.read(ventParamsNotifierProvider);
    _cycleTracker = CycleTracker(peep: params.peep, rr: params.rr);

    return SimulationState.initial(peep: params.peep);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // tick() — called by the presentation Ticker at ~60 fps
  // ═══════════════════════════════════════════════════════════════════════

  /// Advance the simulation by [deltaSeconds] (wall-clock time since last
  /// tick).
  ///
  /// Internally steps the engine at [EngineConstants.dt] (250 Hz),
  /// collecting samples into the circular buffers. The UI state is only
  /// emitted every 3rd frame (~20 fps) to balance visual smoothness
  /// against widget rebuild cost.
  void tick(double deltaSeconds) {
    final params = ref.read(ventParamsNotifierProvider);

    // Clamp delta to avoid spiral-of-death on frame spikes.
    final dt = deltaSeconds.clamp(0.0, 0.04);
    final steps = (dt / EngineConstants.dt).floor();

    // ── Run the engine at 250 Hz ─────────────────────────────────────
    for (int s = 0; s < steps; s++) {
      _simTime += EngineConstants.dt;
      var sample = VentilatorEngine.simulate(params, _simTime);

      // Apply active pathophysiology modifiers (two-phase pipeline).
      var effectiveParams = params;
      final activeEvents = ref.read(activePathophysiologyProvider);
      if (activeEvents.isNotEmpty) {
        final result = PathophysiologyRegistry.apply(
          originalParams: params,
          originalSample: sample,
          activeEvents: activeEvents,
          simTime: _simTime,
        );
        sample = result.sample;
        effectiveParams = result.params;
      }

      final idx = _writeIndex % EngineConstants.bufferSize;
      _pressureBuf[idx] = sample.pressure;
      _flowBuf[idx] = sample.flow;
      _volumeBuf[idx] = sample.volume;
      _writeIndex++;

      _cycleTracker.processSample(sample, _simTime, effectiveParams.peep);
    }

    // ── Advance blood gas washout model ───────────────────────────────
    ref.read(bloodGasLabNotifierProvider.notifier).tick(dt);

    // ── Throttle UI emission to ~20 fps ──────────────────────────────
    _frameCount++;
    if (_frameCount % 3 != 0) return;

    // Build display arrays from the circular buffer.
    final total = _writeIndex;
    final bufSize = EngineConstants.bufferSize;
    final start = (total - bufSize).clamp(0, total);

    final pressure = <double>[];
    final flow = <double>[];
    final volume = <double>[];

    for (int i = start; i < total; i++) {
      final bi = i % bufSize;
      pressure.add(_pressureBuf[bi]);
      flow.add(_flowBuf[bi]);
      volume.add(_volumeBuf[bi]);
    }

    // Pad the beginning with baseline values until the buffer is full.
    while (pressure.length < bufSize) {
      pressure.insert(0, params.peep);
      flow.insert(0, 0);
      volume.insert(0, 0);
    }

    state = SimulationState(
      pressureData: pressure,
      flowData: flow,
      volumeData: volume,
      currentIndex: pressure.length - 1,
      phase: _simTime % params.totalCycleTime < params.inspTime
          ? BreathPhase.inspiration
          : BreathPhase.expiration,
      metrics: _cycleTracker.currentMetrics,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // reset() — clear all buffers and restart simulation clock
  // ═══════════════════════════════════════════════════════════════════════

  /// Reset the simulation to its initial state.
  ///
  /// Clears all waveform buffers, resets the clock and cycle tracker,
  /// and emits a blank [SimulationState]. Called when the user switches
  /// presets or navigates away from the simulator screen.
  void reset() {
    final params = ref.read(ventParamsNotifierProvider);

    _pressureBuf.fillRange(0, _pressureBuf.length, params.peep);
    _flowBuf.fillRange(0, _flowBuf.length, 0);
    _volumeBuf.fillRange(0, _volumeBuf.length, 0);
    _writeIndex = 0;
    _simTime = 0;
    _frameCount = 0;
    _cycleTracker.reset(params.peep, params.rr);
    PathophysiologyRegistry.resetAll();
    ref.read(bloodGasLabNotifierProvider.notifier).reset();
    state = SimulationState.initial(peep: params.peep);
  }
}

// ---------------------------------------------------------------------------
// Derived provider: CycleMetrics from the simulation state.
//
// This replaces the standalone CycleMetricsNotifier — metrics are now
// derived directly from the running simulation.
// ---------------------------------------------------------------------------

/// Latest per-breath clinical metrics (PIP, PEEP, Vte, measured RR).
///
/// Derived from [simulationNotifierProvider]. Recalculates every time
/// the simulation emits a new state (i.e. ~20 fps, but CycleMetrics
/// only actually changes once per breath cycle).
@riverpod
CycleMetrics cycleMetrics(CycleMetricsRef ref) =>
    ref.watch(simulationNotifierProvider).metrics;
