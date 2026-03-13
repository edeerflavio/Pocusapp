import 'dart:math' as math;

import '../../entities/pathophysiology/pathophysiology_entities.dart';
import '../../entities/ventilator_entities.dart';
import '../../enums/ventilation_enums.dart';
import 'pathophysiology_modifier.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DoubleTriggerModifier — breath stacking / double-cycling asynchrony
// ═══════════════════════════════════════════════════════════════════════════

/// Simulates **double-triggering** (breath stacking) asynchrony.
///
/// ## Pathophysiology
///
/// The patient's inspiratory effort fires a second ventilator cycle before
/// the current expiration has completed. This "stacks" two tidal volumes,
/// dramatically increasing total delivered volume and peak pressure.
///
/// Common causes:
/// - High patient drive (pain, anxiety, metabolic acidosis)
/// - Short set inspiratory time vs. patient's neural Ti
/// - Excessive trigger sensitivity
///
/// ## Waveform signs
///
/// - Two inspiratory peaks in rapid succession
/// - Very short or absent expiratory phase between the two cycles
/// - Elevated peak pressure on the second breath (volume stacking)
/// - VTe ~ 2x set VT (alarming for VILI risk)
///
/// ## Model
///
/// Episodic: each breath has a probability of triggering a double cycle
/// based on `event.intensity * severityMultiplier`. When triggered, a
/// second inspiratory phase is injected during early expiration.
///
/// Uses `Random(42)` for deterministic, reproducible event sequences
/// across runs with the same parameters.
///
/// **100 % pure Dart** — no Flutter, no Riverpod.
class DoubleTriggerModifier implements PathophysiologyModifier {
  @override
  PathophysiologyType get type => PathophysiologyType.doubleTrigger;

  // ── Internal state ─────────────────────────────────────────────────────

  /// Deterministic PRNG seeded at 42 for reproducible trigger patterns.
  math.Random _rng = math.Random(42);

  /// Whether we are currently inside a double-trigger episode.
  bool _inDoubleTrigger = false;

  /// Simulation time at which the current episode started.
  double _episodeOnset = -1.0;

  /// Duration of the injected second breath (seconds).
  double _episodeDuration = 0.0;

  /// Volume scale factor for the stacked breath (0–1).
  double _episodeVolumeScale = 0.0;

  /// Breath-cycle ID of the last trigger-decision to avoid re-rolling
  /// within the same breath.
  int _lastDecisionBreathId = -1;

  // ── Constants ──────────────────────────────────────────────────────────

  /// Minimum interval between episodes (seconds).
  ///
  /// Prevents unrealistic back-to-back stacking that would obscure
  /// the characteristic waveform pattern.
  static const double _minInterval = 3.0;

  /// How far into expiration (fraction of tExp) the trigger fires.
  /// 0.1 = very early — clinically realistic.
  static const double _triggerFraction = 0.1;

  // ── Phase 1: modify params ─────────────────────────────────────────────

  /// Double-trigger does not alter pre-engine parameters.
  ///
  /// All effects are post-engine waveform injections.
  @override
  VentParams modifyParams(
    VentParams original,
    PathophysiologyEvent event,
    double simTime,
  ) =>
      original;

  // ── Phase 2: modify sample ─────────────────────────────────────────────

  /// Stochastically injects a second inspiratory phase during early
  /// expiration.
  ///
  /// ### Algorithm
  ///
  /// 1. Identify the breath-cycle boundary (start of expiration).
  /// 2. Roll `_rng.nextDouble()` vs `intensity × severityMultiplier`.
  /// 3. If triggered, inject a second inspiratory envelope for
  ///    40 % of normal Ti (scaled by severity).
  /// 4. The stacked breath's pressure, flow, and volume are
  ///    superimposed on the decaying expiratory waveform.
  @override
  BreathSample modifySample(
    BreathSample original,
    VentParams params,
    PathophysiologyEvent event,
    double simTime,
  ) {
    final cycleTime = params.totalCycleTime;
    final ti = params.inspTime;
    final tInCycle = simTime % cycleTime;

    // ── Trigger decision window ──────────────────────────────────────────
    final triggerPoint = ti + params.expTime * _triggerFraction;
    final inWindow =
        tInCycle >= triggerPoint && tInCycle < triggerPoint + 0.02;

    if (!_inDoubleTrigger && inWindow) {
      final breathId = (simTime / cycleTime).floor();

      // One decision per breath.
      if (breathId != _lastDecisionBreathId) {
        _lastDecisionBreathId = breathId;

        // Respect minimum interval.
        if (_episodeOnset >= 0 && simTime - _episodeOnset < _minInterval) {
          return original;
        }

        /// Severity multiplier: mild 30 %, moderate 60 %, severe 100 %.
        final sevMul = switch (event.severity) {
          PathophysiologySeverity.mild => 0.3,
          PathophysiologySeverity.moderate => 0.6,
          PathophysiologySeverity.severe => 1.0,
        };

        if (_rng.nextDouble() < event.intensity * sevMul) {
          _inDoubleTrigger = true;
          _episodeOnset = simTime;

          /// Stacked breath lasts 40–80 % of normal Ti.
          _episodeDuration = ti * (0.4 + 0.4 * sevMul);

          /// Volume scale: mild ~30 %, moderate ~60 %, severe ~90 %.
          _episodeVolumeScale = 0.3 + 0.6 * sevMul;
        }
      }
    }

    // ── Active episode: inject second breath ─────────────────────────────
    if (_inDoubleTrigger) {
      final elapsed = simTime - _episodeOnset;

      if (elapsed > _episodeDuration) {
        _inDoubleTrigger = false;
        return original;
      }

      /// Progress through stacked breath [0, 1].
      final progress = elapsed / _episodeDuration;

      /// Sinusoidal envelope peaks at mid-inspiration.
      final envelope = math.sin(math.pi * progress);

      /// Stacked volume (mL) = set Vt × scale × envelope.
      final stackedVolMl = params.vt * _episodeVolumeScale * envelope;

      /// Pressure rise from stacked volume (cmH₂O).
      final stackedPressure = stackedVolMl / params.compliance;

      /// Positive flow for the stacked breath (L/min).
      /// Derivative of sinusoidal volume envelope.
      final stackedFlow = params.vt *
          _episodeVolumeScale *
          math.pi /
          _episodeDuration *
          math.cos(math.pi * progress) /
          1000.0 *
          60.0;

      return BreathSample(
        pressure: original.pressure + stackedPressure,
        flow: stackedFlow.abs(),
        volume: original.volume + stackedVolMl,
        phase: BreathPhase.inspiration,
      );
    }

    return original;
  }

  // ── Reset ──────────────────────────────────────────────────────────────

  @override
  void reset() {
    _rng = math.Random(42);
    _inDoubleTrigger = false;
    _episodeOnset = -1.0;
    _episodeDuration = 0.0;
    _episodeVolumeScale = 0.0;
    _lastDecisionBreathId = -1;
  }
}
