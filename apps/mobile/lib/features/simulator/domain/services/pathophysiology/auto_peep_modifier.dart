import 'dart:math' as math;

import '../../entities/pathophysiology/pathophysiology_entities.dart';
import '../../entities/ventilator_entities.dart';
import '../../enums/ventilation_enums.dart';
import 'pathophysiology_modifier.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AutoPeepModifier — dynamic hyperinflation / intrinsic PEEP
// ═══════════════════════════════════════════════════════════════════════════

/// Simulates **auto-PEEP** (intrinsic PEEP / dynamic hyperinflation).
///
/// ## Pathophysiology
///
/// When expiratory time (tExp) is shorter than ~3 × τ, the lung cannot
/// fully empty before the next breath. Volume is "trapped", creating a
/// positive pressure above set PEEP at end-expiration.
///
/// Common causes:
/// - High respiratory rate (short tExp)
/// - High airway resistance (long τ = R × C)
/// - Inverted I:E ratio
///
/// ## Waveform signs
///
/// - Expiratory flow does **not** return to zero before the next
///   inspiration.
/// - Baseline pressure is elevated above set PEEP.
/// - Elevated end-expiratory volume (air trapping).
///
/// ## Mathematical model
///
/// **Trapping factor** per breath:
///   `k = e^(−tExp / τ)`
///
/// At steady state the trapped volume accumulates geometrically:
///   `Vtrapped_ss = Vt × k / (1 − k)`
///
/// The resulting intrinsic PEEP is:
///   `autoPEEP = Vtrapped_ss / C`
///
/// The modifier scales this by `event.intensity` and the severity
/// multiplier, and caps the result at 15 cmH₂O to stay within
/// clinically plausible bounds.
///
/// **100 % pure Dart** — no Flutter, no Riverpod.
class AutoPeepModifier implements PathophysiologyModifier {
  @override
  PathophysiologyType get type => PathophysiologyType.autoPeep;

  // ── Internal state ─────────────────────────────────────────────────────

  /// Smoothed auto-PEEP value that ramps toward the steady-state target
  /// to avoid discontinuities when the event is first activated.
  double _smoothedAutoPeep = 0.0;

  // ── Constants ──────────────────────────────────────────────────────────

  /// Minimum auto-PEEP (cmH₂O) below which the effect is not applied.
  ///
  /// Sub-0.5 cmH₂O values are clinically insignificant and would only
  /// introduce numerical noise into the waveform.
  static const double _minThreshold = 0.5;

  /// Hard cap on the auto-PEEP contribution (cmH₂O).
  ///
  /// Even extreme scenarios rarely exceed 15 cmH₂O of intrinsic PEEP.
  /// Capping prevents unrealistic runaway values from user error.
  static const double _maxAutoPeep = 15.0;

  /// Exponential smoothing factor (0–1). Lower = slower ramp-up.
  ///
  /// At 250 Hz engine rate, 0.005 ≈ 200 ticks (0.8 s) to reach 63%
  /// of the target — fast enough to be visible but slow enough to
  /// look physiological.
  static const double _smoothingAlpha = 0.005;

  // ── Phase 1: modify params ─────────────────────────────────────────────

  /// Computes the steady-state auto-PEEP and adds it to [VentParams.peep].
  ///
  /// ### Algorithm
  ///
  /// 1. Compute the RC time constant τ = R × C / 1000.
  /// 2. Compute the trapping factor `k = e^(−tExp / τ)`.
  ///    If k < 0.01 (tExp > 4.6 τ), auto-PEEP is negligible → skip.
  /// 3. Compute steady-state trapped volume:
  ///    `Vtrapped = Vt × k / (1 − k)` (mL).
  /// 4. Convert to pressure: `autoPeep = Vtrapped / C` (cmH₂O).
  /// 5. Scale by severity multiplier and intensity.
  /// 6. Clamp to \[0, _maxAutoPeep\].
  /// 7. Smooth toward target to avoid abrupt jumps.
  /// 8. If smoothed value > _minThreshold, add to PEEP.
  @override
  VentParams modifyParams(
    VentParams original,
    PathophysiologyEvent event,
    double simTime,
  ) {
    final tau = original.tau; // R × C / 1000 (seconds)
    final tExp = original.expTime; // expiratory time (seconds)

    // ── Step 2: trapping factor ──────────────────────────────────────────
    /// Fraction of end-inspiratory volume remaining at end-expiration.
    /// k approaches 1 when tExp << τ (severe trapping) and 0 when
    /// tExp >> τ (complete emptying).
    final k = math.exp(-tExp / tau);

    // If the lung empties almost completely, no meaningful auto-PEEP.
    if (k < 0.01) {
      _smoothedAutoPeep *= (1.0 - _smoothingAlpha);
      return original;
    }

    // ── Step 3: steady-state trapped volume (mL) ─────────────────────────
    /// Geometric series sum: VT × k / (1 − k).
    /// This is the volume that would be trapped after infinite breaths
    /// at the current settings.
    final vt = switch (original.mode) {
      VentMode.vcv => original.vt.toDouble(),
      VentMode.pcv =>
        original.compliance * original.pip * (1.0 - math.exp(-original.inspTime / tau)),
      VentMode.psv =>
        original.compliance * original.ps * (1.0 - math.exp(-original.inspTime / tau)),
    };
    final trappedVolume = vt * k / (1.0 - k);

    // ── Step 4: convert to pressure ──────────────────────────────────────
    /// autoPEEP = Vtrapped / C (using compliance in mL/cmH₂O).
    final rawAutoPeep = trappedVolume / original.compliance;

    // ── Step 5: scale by severity and intensity ──────────────────────────
    /// Severity multiplier: mild ≈ 0.25, moderate ≈ 0.5, severe ≈ 1.0.
    final severityMultiplier = switch (event.severity) {
      PathophysiologySeverity.mild => 0.25,
      PathophysiologySeverity.moderate => 0.5,
      PathophysiologySeverity.severe => 1.0,
    };
    final scaledAutoPeep = rawAutoPeep * severityMultiplier * event.intensity;

    // ── Step 6: clamp ────────────────────────────────────────────────────
    final targetAutoPeep = scaledAutoPeep.clamp(0.0, _maxAutoPeep);

    // ── Step 7: exponential smoothing ────────────────────────────────────
    /// Avoids an abrupt pressure jump when the event is toggled on.
    /// Each tick moves _smoothedAutoPeep toward the target by α.
    _smoothedAutoPeep +=
        _smoothingAlpha * (targetAutoPeep - _smoothedAutoPeep);

    // ── Step 8: apply if significant ─────────────────────────────────────
    if (_smoothedAutoPeep < _minThreshold) {
      return original;
    }

    return original.copyWith(
      peep: original.peep + _smoothedAutoPeep,
    );
  }

  // ── Phase 2: modify sample ─────────────────────────────────────────────

  /// Adds waveform artefacts characteristic of auto-PEEP:
  ///
  /// - **Residual expiratory flow**: the flow trace does not return to
  ///   zero before the next inspiration, scaled by intensity.
  ///   Clinical correlate: this is the hallmark sign of air trapping on
  ///   the ventilator flow waveform.
  ///
  /// - **Elevated end-expiratory volume**: a volume offset proportional
  ///   to the smoothed auto-PEEP × compliance, representing the gas
  ///   trapped in the lung.
  @override
  BreathSample modifySample(
    BreathSample original,
    VentParams params,
    PathophysiologyEvent event,
    double simTime,
  ) {
    if (_smoothedAutoPeep < _minThreshold) return original;

    // Only modify during expiration — inspiration is handled by the
    // elevated PEEP in modifyParams.
    if (original.phase != BreathPhase.expiration) return original;

    /// Residual expiratory flow (L/min, negative).
    ///
    /// A small negative flow at end-expiration signals to the learner
    /// that gas is still leaving the alveoli when the next breath starts.
    /// Scaled by intensity: at intensity 1.0 → −2 L/min residual.
    final residualFlow = -2.0 * event.intensity;
    final adjustedFlow = math.min(original.flow, residualFlow);

    /// Trapped volume offset (mL).
    ///
    /// End-expiratory volume = autoPEEP × C.
    /// This elevates the volume baseline on the waveform.
    final trappedVolumeMl = _smoothedAutoPeep * params.compliance;
    final adjustedVolume = original.volume + trappedVolumeMl;

    return BreathSample(
      pressure: original.pressure,
      flow: adjustedFlow,
      volume: adjustedVolume,
      phase: original.phase,
    );
  }

  // ── Reset ──────────────────────────────────────────────────────────────

  @override
  void reset() {
    _smoothedAutoPeep = 0.0;
  }
}
