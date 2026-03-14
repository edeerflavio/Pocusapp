import '../../domain/entities/ventilator_entities.dart';
import '../../domain/enums/ventilation_enums.dart';

/// Predefined ventilator parameter sets for common clinical scenarios.
///
/// Each preset configures compliance, resistance, and ventilator settings
/// to simulate a specific lung pathology, teaching the learner how
/// mechanics affect waveforms and which adjustments are appropriate.
abstract final class ClinicalPresets {
  /// Map from [ClinicalPresetType] to its corresponding [VentParams].
  static const Map<ClinicalPresetType, VentParams> presets = {
    // ── Normal adult lung ──────────────────────────────────────────────
    // C ≈ 50 mL/cmH₂O, R ≈ 5 cmH₂O·s/L.
    // Standard VCV with protective settings.
    ClinicalPresetType.normal: VentParams(
      mode: VentMode.vcv,
      compliance: 50,
      resistance: 5,
      peep: 5,
      rr: 14,
      vt: 450,
      pip: 20,
      ps: 10,
      fio2: 21,
      ieRatio: 2.0,
      patientEffort: 0,
    ),

    // ── SDRA / ARDS ────────────────────────────────────────────────────
    // Very low compliance (20 mL/cmH₂O), moderate resistance (10).
    // PCV with lung-protective settings: high PEEP, low driving pressure,
    // high FiO₂. Teaches the learner to manage stiff lungs.
    ClinicalPresetType.sdra: VentParams(
      mode: VentMode.pcv,
      compliance: 20,
      resistance: 10,
      peep: 14,
      rr: 22,
      vt: 350,
      pip: 14,
      ps: 10,
      fio2: 70,
      ieRatio: 2.0,
      patientEffort: 0,
    ),

    // ── Asma / Asthma ──────────────────────────────────────────────────
    // Normal-to-high compliance (60), very high resistance (20).
    // Risk of dynamic hyperinflation and auto-PEEP.
    // Lower RR and longer expiratory time (1:3) to prevent air trapping.
    ClinicalPresetType.asma: VentParams(
      mode: VentMode.vcv,
      compliance: 60,
      resistance: 20,
      peep: 3,
      rr: 10,
      vt: 400,
      pip: 20,
      ps: 10,
      fio2: 40,
      ieRatio: 3.0,
      patientEffort: 0,
    ),

    // ── DPOC / COPD ────────────────────────────────────────────────────
    // High compliance (80, loss of elastic recoil), high resistance (18).
    // Long τ → requires prolonged expiratory time to avoid air trapping.
    // Low PEEP to avoid worsening hyperinflation.
    ClinicalPresetType.dpoc: VentParams(
      mode: VentMode.vcv,
      compliance: 80,
      resistance: 18,
      peep: 3,
      rr: 12,
      vt: 400,
      pip: 20,
      ps: 10,
      fio2: 35,
      ieRatio: 3.0,
      patientEffort: 0,
    ),

    // ── SDRA com APRV ────────────────────────────────────────────────
    // Very low compliance (20), moderate resistance (10).
    // APRV with P-high 28 cmH₂O, brief release (0.6 s).
    // Teaches the learner to manage refractory ARDS with APRV.
    ClinicalPresetType.sdraAprv: VentParams(
      mode: VentMode.aprv,
      compliance: 20,
      resistance: 10,
      peep: 0,
      rr: 14,
      vt: 350,
      pip: 28,
      ps: 10,
      fio2: 80,
      ieRatio: 2.0,
      patientEffort: 0,
      pHigh: 28,
      pLow: 0,
      tHigh: 4.5,
      tLow: 0.6,
      spontaneousRR: 12,
    ),
  };

  /// Display title in Portuguese for each preset.
  static String title(ClinicalPresetType type) => switch (type) {
        ClinicalPresetType.normal => 'Pulmão Normal',
        ClinicalPresetType.sdra => 'SDRA (ARDS)',
        ClinicalPresetType.asma => 'Asma Grave',
        ClinicalPresetType.dpoc => 'DPOC',
        ClinicalPresetType.sdraAprv => 'SDRA — APRV',
      };

  /// Short description in Portuguese for each preset.
  static String description(ClinicalPresetType type) => switch (type) {
        ClinicalPresetType.normal =>
          'Compliance e resistência normais. Ventilação protetora padrão.',
        ClinicalPresetType.sdra =>
          'Compliance muito baixa, PEEP alta, FiO₂ elevada. '
              'Ventilação protetora para SDRA.',
        ClinicalPresetType.asma =>
          'Alta resistência, risco de auto-PEEP e hiperinsuflação dinâmica. '
              'Tempo expiratório prolongado.',
        ClinicalPresetType.dpoc =>
          'Compliance elevada, alta resistência. Risco de air trapping. '
              'I:E 1:3 ou maior.',
        ClinicalPresetType.sdraAprv =>
          'SDRA refratária com APRV. P-high 28 cmH₂O, liberação breve. '
              'Respiração espontânea permitida.',
      };
}
