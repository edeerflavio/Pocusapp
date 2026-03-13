import 'dart:math' as math;

import '../../entities/pathophysiology/pathophysiology_entities.dart';
import '../../entities/ventilator_entities.dart';
import '../../enums/ventilation_enums.dart';
import 'pathophysiology_modifier.dart';

// ═══════════════════════════════════════════════════════════════════════════
// BronchospasmModifier — acute bronchial constriction
// ═══════════════════════════════════════════════════════════════════════════

/// Simulates **acute bronchospasm** (asthma exacerbation, anaphylaxis).
///
/// ## Pathophysiology
///
/// Smooth-muscle contraction in medium and small airways dramatically
/// increases resistance. Unlike secretion (which is progressive),
/// bronchospasm onset is **sudden** — the learner should notice an
/// abrupt change in waveforms.
///
/// Expiratory resistance increases more than inspiratory (dynamic
/// airway collapse during expiration), producing the characteristic
/// prolonged expiration and auto-PEEP.
///
/// ## Waveform signs
///
/// - PIP spikes (VCV) or Vt drops (PCV) immediately.
/// - Expiratory flow curve becomes "scooped out" / concave —
///   flow decays slowly, often not reaching zero.
/// - Auto-PEEP develops secondarily (use with [AutoPeepModifier]
///   for the full clinical picture).
/// - Classic capnography: "shark-fin" CO₂ waveform (not rendered
///   here, but the flow signature is analogous).
///
/// ## Model
///
/// | Severity | Resistance multiplier |
/// |----------|-----------------------|
/// | mild     | x2                    |
/// | moderate | x3.5                  |
/// | severe   | x5                    |
///
/// The expiratory flow curve is additionally "scooped" by applying
/// a concavity factor that retards the exponential decay, making the
/// flow trace dip below the normal RC curve before slowly recovering.
///
/// **100 % pure Dart** — no Flutter, no Riverpod.
class BronchospasmModifier implements PathophysiologyModifier {
  @override
  PathophysiologyType get type => PathophysiologyType.bronchospasm;

  // ── Phase 1: modify params (multiply resistance) ───────────────────────

  /// Multiplies airway resistance by a severity-dependent factor.
  ///
  /// Onset is instant — no ramp. This matches the clinical reality
  /// of acute bronchospasm (e.g. allergen exposure, cold air).
  @override
  VentParams modifyParams(
    VentParams original,
    PathophysiologyEvent event,
    double simTime,
  ) {
    /// Resistance multiplier table.
    ///
    /// Values derived from published spirometry data in acute asthma:
    /// - mild: Raw doubles (~from 5 to 10 cmH₂O/L/s)
    /// - moderate: Raw triples (~from 5 to 17 cmH₂O/L/s)
    /// - severe: Raw quintuples (~from 5 to 25 cmH₂O/L/s, status asthmaticus)
    final multiplier = switch (event.severity) {
      PathophysiologySeverity.mild => 2.0,
      PathophysiologySeverity.moderate => 3.5,
      PathophysiologySeverity.severe => 5.0,
    };

    /// Scale between 1.0 (no effect) and full multiplier by intensity.
    final effectiveMultiplier = 1.0 + (multiplier - 1.0) * event.intensity;

    return original.copyWith(
      resistance: original.resistance * effectiveMultiplier,
    );
  }

  // ── Phase 2: modify sample (scooped expiratory flow) ───────────────────

  /// Distorts the expiratory flow curve to produce the characteristic
  /// "scooped" or concave shape of obstructive disease.
  ///
  /// ### Mechanism
  ///
  /// In normal lungs, expiratory flow decays as a clean exponential.
  /// In bronchospasm, dynamic airway collapse during expiration causes
  /// flow limitation — the curve bows inward (toward zero) before
  /// slowly recovering.
  ///
  /// We model this by scaling the expiratory flow by a concavity
  /// function: `flow × (1 − concavity × sin(π × progress))`,
  /// where progress is the fractional position in expiration.
  @override
  BreathSample modifySample(
    BreathSample original,
    VentParams params,
    PathophysiologyEvent event,
    double simTime,
  ) {
    // Only modify during expiration.
    if (original.phase != BreathPhase.expiration) return original;

    final cycleTime = params.totalCycleTime;
    final ti = params.inspTime;
    final tInCycle = simTime % cycleTime;
    final tExp = tInCycle - ti;

    if (tExp < 0) return original;

    /// Progress through expiration [0, 1].
    final progress = (tExp / params.expTime).clamp(0.0, 1.0);

    /// Concavity depth scaled by severity and intensity.
    /// mild ≈ 0.15, moderate ≈ 0.30, severe ≈ 0.45.
    final concavityBase = switch (event.severity) {
      PathophysiologySeverity.mild => 0.15,
      PathophysiologySeverity.moderate => 0.30,
      PathophysiologySeverity.severe => 0.45,
    };
    final concavity = concavityBase * event.intensity;

    /// Scooping function: peaks at mid-expiration, zero at boundaries.
    final scoop = concavity * math.sin(math.pi * progress);

    /// Apply: reduce flow magnitude (flow is negative during expiration).
    /// Multiplier < 1 means less flow → slower emptying → scooped curve.
    final flowMultiplier = 1.0 - scoop;

    return BreathSample(
      pressure: original.pressure,
      flow: original.flow * flowMultiplier,
      volume: original.volume,
      phase: original.phase,
    );
  }

  // ── Reset ──────────────────────────────────────────────────────────────

  /// Bronchospasm is stateless (instant onset, no accumulation).
  @override
  void reset() {}
}
