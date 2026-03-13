import '../../entities/pathophysiology/pathophysiology_entities.dart';
import '../../entities/ventilator_entities.dart';
import 'pathophysiology_modifier.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PneumothoraxModifier — abrupt compliance drop from pleural air
// ═══════════════════════════════════════════════════════════════════════════

/// Simulates **pneumothorax** (simple or tension).
///
/// ## Pathophysiology
///
/// Air in the pleural space compresses the lung parenchyma, causing an
/// abrupt drop in compliance. In tension pneumothorax, the mediastinal
/// shift also compresses vascular structures, producing hemodynamic
/// compromise. On the ventilator, the stiff lung translates to:
///
/// ## Waveform signs
///
/// - **VCV**: PIP and Pplat spike simultaneously (both rise because
///   compliance dropped — not just resistive).
/// - **PCV/PSV**: tidal volume drops dramatically while pressure is
///   maintained.
/// - Driving pressure (DP) and plateau pressure exceed safe thresholds.
/// - SpO₂ and PaO₂ fall; tachycardia and hypotension ensue.
///
/// ## Model (single-compartment approximation)
///
/// | Severity | Compliance reduction | Resistance increase |
/// |----------|---------------------|---------------------|
/// | mild     | -20 %               | 0 %                 |
/// | moderate | -45 %               | 0 %                 |
/// | severe   | -70 %               | +30 % (tension)     |
///
/// Onset is **abrupt** — no ramp-up. This is the clinical reality:
/// a pneumothorax can develop acutely (e.g. barotrauma, central line
/// insertion, thoracentesis).
///
/// At severe level the additional resistance models the increased
/// airway impedance from mediastinal shift compressing the
/// contralateral bronchus.
///
/// **100 % pure Dart** — no Flutter, no Riverpod.
class PneumothoraxModifier implements PathophysiologyModifier {
  @override
  PathophysiologyType get type => PathophysiologyType.pneumothorax;

  // ── Phase 1: modify params ─────────────────────────────────────────────

  /// Reduces compliance (and optionally increases resistance) to model
  /// the mechanical effects of pleural air.
  ///
  /// ### Steps
  ///
  /// 1. Look up compliance reduction and resistance increase from severity.
  /// 2. Scale by `event.intensity`.
  /// 3. Apply multiplicatively: `C_new = C × (1 − reduction)`,
  ///    `R_new = R × (1 + increase)`.
  /// 4. Clamp compliance to a floor of 5 mL/cmH₂O to prevent
  ///    division-by-zero in the engine.
  @override
  VentParams modifyParams(
    VentParams original,
    PathophysiologyEvent event,
    double simTime,
  ) {
    // ── Step 1: severity tables ──────────────────────────────────────────
    /// Compliance reduction fraction (0–1).
    final compReduction = switch (event.severity) {
      PathophysiologySeverity.mild => 0.20,
      PathophysiologySeverity.moderate => 0.45,
      PathophysiologySeverity.severe => 0.70,
    };

    /// Resistance increase fraction (only at severe = tension).
    final resIncrease = switch (event.severity) {
      PathophysiologySeverity.mild => 0.0,
      PathophysiologySeverity.moderate => 0.0,
      PathophysiologySeverity.severe => 0.30,
    };

    // ── Step 2: scale by intensity ───────────────────────────────────────
    final effectiveCompDrop = compReduction * event.intensity;
    final effectiveResIncrease = resIncrease * event.intensity;

    // ── Step 3–4: apply ──────────────────────────────────────────────────
    final newCompliance =
        (original.compliance * (1.0 - effectiveCompDrop)).clamp(5.0, 200.0);
    final newResistance = original.resistance * (1.0 + effectiveResIncrease);

    return original.copyWith(
      compliance: newCompliance,
      resistance: newResistance,
    );
  }

  // ── Phase 2: modify sample ─────────────────────────────────────────────

  /// Pneumothorax is fully modelled in the param phase — the engine
  /// recalculates the waveform with the reduced compliance.
  @override
  BreathSample modifySample(
    BreathSample original,
    VentParams params,
    PathophysiologyEvent event,
    double simTime,
  ) =>
      original;

  // ── Reset ──────────────────────────────────────────────────────────────

  /// Pneumothorax is stateless (abrupt onset, no accumulation).
  @override
  void reset() {}
}
