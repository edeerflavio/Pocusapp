import '../entities/ventilator_entities.dart';
import '../enums/ventilation_enums.dart';

/// Tracks breath boundaries and computes per-cycle clinical metrics.
///
/// The simulation loop feeds every [BreathSample] into [processSample].
/// When a phase transition from inspiration to expiration is detected,
/// the accumulated peak values are "frozen" into a [CycleMetrics] snapshot
/// and a new accumulation cycle begins.
///
/// **Pure Dart** — no Flutter, no Riverpod.
class CycleTracker {
  CycleTracker({required double peep, required int rr})
      : _setPeep = peep,
        _setRr = rr;

  double _setPeep;
  int _setRr;

  // ── Accumulation state ─────────────────────────────────────────────────

  BreathPhase _prevPhase = BreathPhase.expiration;

  /// Peak pressure seen during the current inspiratory phase.
  double _peakPressure = 0;

  /// Peak volume seen during the current inspiratory phase (mL).
  double _peakVolume = 0;

  /// Timestamp of the last breath onset (start of inspiration).
  double _lastBreathOnsetTime = 0;

  /// Measured RR derived from inter-breath interval.
  int _measuredRr = 0;

  /// Number of completed breath cycles.
  int _cycleCount = 0;

  // ── Output ─────────────────────────────────────────────────────────────

  CycleMetrics _currentMetrics = CycleMetrics.initial();

  /// The latest per-breath metrics snapshot.
  CycleMetrics get currentMetrics => _currentMetrics;

  // ── API ────────────────────────────────────────────────────────────────

  /// Feed a single engine sample. Call this at every simulation step.
  void processSample(BreathSample sample, double simTime, double peep) {
    _setPeep = peep;

    if (sample.phase == BreathPhase.inspiration) {
      // Track peaks during inspiration.
      if (sample.pressure > _peakPressure) {
        _peakPressure = sample.pressure;
      }
      if (sample.volume > _peakVolume) {
        _peakVolume = sample.volume;
      }

      // Detect breath onset (transition from expiration → inspiration).
      if (_prevPhase == BreathPhase.expiration) {
        // New breath started — compute RR from interval.
        if (_cycleCount > 0 && simTime > _lastBreathOnsetTime) {
          final interval = simTime - _lastBreathOnsetTime;
          if (interval > 0.5) {
            // Plausible interval (> 0.5 s = < 120 bpm).
            _measuredRr = (60.0 / interval).round();
          }
        }
        _lastBreathOnsetTime = simTime;
        _cycleCount++;
      }
    } else {
      // Expiration phase.

      // Detect transition from inspiration → expiration = breath boundary.
      // Freeze the accumulated metrics.
      if (_prevPhase == BreathPhase.inspiration) {
        _currentMetrics = CycleMetrics(
          pip: _peakPressure.round(),
          peep: _setPeep.round(),
          vte: _peakVolume.round(),
          rr: _measuredRr > 0 ? _measuredRr : _setRr,
        );

        // Reset accumulators for the next cycle.
        _peakPressure = 0;
        _peakVolume = 0;
      }
    }

    _prevPhase = sample.phase;
  }

  /// Reset all tracking state (e.g. when simulation restarts).
  void reset(double peep, int rr) {
    _setPeep = peep;
    _setRr = rr;
    _prevPhase = BreathPhase.expiration;
    _peakPressure = 0;
    _peakVolume = 0;
    _lastBreathOnsetTime = 0;
    _measuredRr = 0;
    _cycleCount = 0;
    _currentMetrics = CycleMetrics.initial();
  }
}
