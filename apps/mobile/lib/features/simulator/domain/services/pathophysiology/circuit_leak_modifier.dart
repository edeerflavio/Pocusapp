import '../../entities/pathophysiology/pathophysiology_entities.dart';
import '../../entities/ventilator_entities.dart';
import '../../enums/ventilation_enums.dart';
import 'pathophysiology_modifier.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CircuitLeakModifier — ventilator circuit or cuff leak
// ═══════════════════════════════════════════════════════════════════════════

/// Simulates a **circuit leak** (cuff leak, circuit disconnection,
/// or bronchopleural fistula).
///
/// ## Pathophysiology
///
/// Gas escapes through a leak point in the ventilator circuit, reducing
/// the effective volume delivered to the patient's lungs. The leak can
/// occur at the ETT cuff (most common), a circuit connector, or through
/// a bronchopleural fistula.
///
/// ## Waveform signs
///
/// - **VCV**: PIP may drop slightly but the hallmark is VTe << VTi
///   (exhaled volume significantly less than inspired).
/// - **PCV/PSV**: pressure is maintained but Vte drops.
/// - Persistent low-level flow during the expiratory pause (gas
///   escaping through the leak).
/// - Minute volume alarm triggers as effective ventilation decreases.
///
/// ## Model
///
/// `leakFraction` = 0.1–0.5 based on intensity and severity.
///
/// Volume is reduced: `V_effective = V_original × (1 − leakFraction)`.
/// Pressure drops proportionally: the elastic recoil pressure decreases
/// because less volume is retained in the lung.
///
/// | Severity | Max leak fraction |
/// |----------|-------------------|
/// | mild     | 10 %              |
/// | moderate | 25 %              |
/// | severe   | 50 %              |
///
/// **100 % pure Dart** — no Flutter, no Riverpod.
class CircuitLeakModifier implements PathophysiologyModifier {
  @override
  PathophysiologyType get type => PathophysiologyType.circuitLeak;

  // ── Phase 1: modify params ─────────────────────────────────────────────

  /// Circuit leak does not alter pre-engine parameters.
  ///
  /// The engine computes the "intended" delivery; the leak acts on
  /// the resulting sample to simulate gas escaping.
  @override
  VentParams modifyParams(
    VentParams original,
    PathophysiologyEvent event,
    double simTime,
  ) =>
      original;

  // ── Phase 2: modify sample (reduce delivered volume and pressure) ──────

  /// Reduces volume and pressure to simulate gas escaping through
  /// the leak.
  ///
  /// ### Algorithm
  ///
  /// 1. Compute `leakFraction` from severity and intensity.
  /// 2. Reduce volume: `V × (1 − leakFraction)`.
  /// 3. Reduce the elastic component of pressure proportionally:
  ///    `P_new = PEEP + (P_original − PEEP) × (1 − leakFraction)`.
  ///    PEEP itself is maintained by the ventilator's valve.
  /// 4. During expiration, add a small positive leak flow to represent
  ///    gas escaping outward through the circuit breach.
  @override
  BreathSample modifySample(
    BreathSample original,
    VentParams params,
    PathophysiologyEvent event,
    double simTime,
  ) {
    // ── Step 1: compute leak fraction ────────────────────────────────────
    /// Maximum leak at full intensity for each severity tier.
    final maxLeak = switch (event.severity) {
      PathophysiologySeverity.mild => 0.10,
      PathophysiologySeverity.moderate => 0.25,
      PathophysiologySeverity.severe => 0.50,
    };
    final leakFraction = maxLeak * event.intensity;

    // ── Step 2: reduce volume ────────────────────────────────────────────
    final retainedVolume = original.volume * (1.0 - leakFraction);

    // ── Step 3: reduce elastic pressure component ────────────────────────
    /// PEEP is maintained by the ventilator's exhalation valve.
    /// Only the elastic recoil above PEEP is affected.
    final elasticDelta = original.pressure - params.peep;
    final reducedPressure = params.peep + elasticDelta * (1.0 - leakFraction);

    // ── Step 4: leak flow during expiration ──────────────────────────────
    /// A small constant positive flow during expiration represents
    /// gas escaping through the circuit breach. This is the visual
    /// clue that distinguishes a leak from simply reduced compliance.
    var adjustedFlow = original.flow;
    if (original.phase == BreathPhase.expiration) {
      /// Leak flow magnitude (L/min): mild ~1, severe ~5.
      final leakFlow = 1.0 + 9.0 * leakFraction;
      adjustedFlow = original.flow + leakFlow;
    }

    return BreathSample(
      pressure: reducedPressure,
      flow: adjustedFlow,
      volume: retainedVolume,
      phase: original.phase,
    );
  }

  // ── Reset ──────────────────────────────────────────────────────────────

  /// Circuit leak is stateless (constant effect while active).
  @override
  void reset() {}
}
