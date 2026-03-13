import '../../entities/pathophysiology/pathophysiology_entities.dart';
import '../../entities/ventilator_entities.dart';
import 'pathophysiology_modifier.dart';

// ═══════════════════════════════════════════════════════════════════════════
// RightMainstemModifier — right mainstem bronchus intubation
// ═══════════════════════════════════════════════════════════════════════════

/// Simulates **right mainstem bronchus intubation** (selective
/// intubation).
///
/// ## Pathophysiology
///
/// The endotracheal tube migrates distally past the carina into the
/// right mainstem bronchus (right > left because of the bronchial
/// anatomy — the right bronchus has a wider angle). Only the right
/// lung is ventilated; the left lung atelectases.
///
/// This effectively:
/// - **Halves** the functional compliance (one lung instead of two).
/// - **Increases** resistance modestly (narrower single-bronchus path).
/// - **Increases** dead-space fraction (left lung is perfused but not
///   ventilated → V/Q mismatch → hypoxemia).
///
/// ## Waveform signs
///
/// - **VCV**: PIP rises sharply (low compliance); Pplat rises.
/// - **PCV/PSV**: Vt drops to ~50 % of baseline.
/// - SpO₂ falls despite maintained minute ventilation.
/// - Asymmetric chest rise on physical exam (not rendered).
///
/// ## Model
///
/// Fixed mechanical changes (independent of severity — selective
/// intubation is an anatomical finding, not graded):
///
/// | Parameter  | Change |
/// |------------|--------|
/// | Compliance | −45 %  |
/// | Resistance | +20 %  |
///
/// The `event.intensity` slider scales the effect to allow pedagogical
/// "partial" intubation (tube at carina level, partially obstructing
/// the left bronchus) vs full selective intubation.
///
/// **100 % pure Dart** — no Flutter, no Riverpod.
class RightMainstemModifier implements PathophysiologyModifier {
  @override
  PathophysiologyType get type =>
      PathophysiologyType.rightMainstemIntubation;

  // ── Constants ──────────────────────────────────────────────────────────

  /// Compliance reduction fraction for one-lung ventilation.
  ///
  /// Two-lung → one-lung approximately halves compliance. We use 45 %
  /// rather than 50 % because the right lung is slightly larger than
  /// the left (55:45 split).
  static const double _complianceReduction = 0.45;

  /// Resistance increase fraction.
  ///
  /// Single bronchus has a smaller cross-section → modest increase.
  static const double _resistanceIncrease = 0.20;

  // ── Phase 1: modify params ─────────────────────────────────────────────

  /// Reduces compliance by 45 % and increases resistance by 20 %,
  /// scaled by `event.intensity`.
  ///
  /// Severity is **not used** — the anatomical defect is binary
  /// (tube either is or isn't in the right mainstem). The intensity
  /// slider alone controls the magnitude for teaching purposes.
  @override
  VentParams modifyParams(
    VentParams original,
    PathophysiologyEvent event,
    double simTime,
  ) {
    final compDrop = _complianceReduction * event.intensity;
    final resIncrease = _resistanceIncrease * event.intensity;

    final newCompliance =
        (original.compliance * (1.0 - compDrop)).clamp(5.0, 200.0);
    final newResistance = original.resistance * (1.0 + resIncrease);

    return original.copyWith(
      compliance: newCompliance,
      resistance: newResistance,
    );
  }

  // ── Phase 2: modify sample ─────────────────────────────────────────────

  /// No post-engine modifications — all effects are via params.
  @override
  BreathSample modifySample(
    BreathSample original,
    VentParams params,
    PathophysiologyEvent event,
    double simTime,
  ) =>
      original;

  // ── Reset ──────────────────────────────────────────────────────────────

  /// Stateless modifier (anatomical position, no accumulation).
  @override
  void reset() {}
}
