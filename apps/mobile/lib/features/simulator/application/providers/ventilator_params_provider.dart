import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/presets/clinical_presets.dart';
import '../../domain/entities/ventilator_entities.dart';
import '../../domain/enums/ventilation_enums.dart';
import 'patient_provider.dart';
import 'simulation_provider.dart';

part 'ventilator_params_provider.g.dart';

// ---------------------------------------------------------------------------
// VentParamsNotifier — manages all operator-settable ventilator knobs.
//
// Initialised from the "normal" clinical preset. Each setter emits a new
// immutable VentParams snapshot; downstream providers (derived mechanics,
// simulation engine, ABG analyzer) react automatically via Riverpod.
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class VentParamsNotifier extends _$VentParamsNotifier {
  @override
  VentParams build() => ClinicalPresets.presets[ClinicalPresetType.normal]!;

  // ── Ventilator settings ──────────────────────────────────────────────

  void updateMode(VentMode mode) => state = state.copyWith(mode: mode);

  void updateRR(int rr) => state = state.copyWith(rr: rr);

  void updatePeep(double peep) => state = state.copyWith(peep: peep);

  void updateFio2(int fio2) => state = state.copyWith(fio2: fio2);

  void updateIE(double ie) => state = state.copyWith(ieRatio: ie);

  void updateVT(int vt) => state = state.copyWith(vt: vt);

  void updatePIP(double pip) => state = state.copyWith(pip: pip);

  void updatePS(double ps) => state = state.copyWith(ps: ps);

  void updateEffort(double effort) =>
      state = state.copyWith(patientEffort: effort);

  // ── Lung mechanics ───────────────────────────────────────────────────

  void updateCompliance(double c) => state = state.copyWith(compliance: c);

  void updateResistance(double r) => state = state.copyWith(resistance: r);

  // ── APRV-specific ─────────────────────────────────────────────────

  void updatePHigh(double v) => state = state.copyWith(pHigh: v);

  void updatePLow(double v) => state = state.copyWith(pLow: v);

  void updateTHigh(double v) => state = state.copyWith(tHigh: v);

  void updateTLow(double v) => state = state.copyWith(tLow: v);

  void updateSpontaneousRR(int v) => state = state.copyWith(spontaneousRR: v);

  // ── Presets ──────────────────────────────────────────────────────────

  /// Apply a clinical preset. Loads all mechanical and ventilator
  /// parameters from the preset, but preserves the current ventilation
  /// mode if the user has manually changed it (unless the preset
  /// explicitly requires a specific mode, like APRV).
  void applyPreset(ClinicalPresetType preset) {
    final presetParams = ClinicalPresets.presets[preset]!;
    // APRV preset must force APRV mode; otherwise preserve current mode.
    final preserveMode = presetParams.mode != VentMode.aprv;
    if (preserveMode) {
      state = presetParams.copyWith(mode: state.mode);
    } else {
      state = presetParams;
    }
  }
}

// ---------------------------------------------------------------------------
// ActivePreset — tracks which preset is currently selected (null = custom).
//
// Set to null whenever the user manually adjusts any parameter after
// loading a preset.
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class ActivePreset extends _$ActivePreset {
  @override
  ClinicalPresetType? build() => ClinicalPresetType.normal;

  void select(ClinicalPresetType? preset) => state = preset;
}

// ---------------------------------------------------------------------------
// Derived mechanics providers — recalculate from VentParams + CycleMetrics.
//
// These use the measured Vte from CycleMetrics when available (> 0),
// falling back to the set Vt from VentParams before the first breath.
// ---------------------------------------------------------------------------

/// Driving Pressure (cmH₂O) = Vte / Compliance.
///
/// The strongest independent predictor of mortality in ARDS (Amato 2015).
/// Target ≤ 15 cmH₂O. Uses measured Vte when available, otherwise set Vt.
@riverpod
double drivingPressure(DrivingPressureRef ref) {
  final p = ref.watch(ventParamsNotifierProvider);
  final metrics = ref.watch(cycleMetricsProvider);
  final vte = metrics.vte > 0 ? metrics.vte.toDouble() : p.vt.toDouble();
  return vte / p.compliance;
}

/// Plateau Pressure (cmH₂O) = PEEP + Driving Pressure.
///
/// Reflects alveolar distending pressure. Target ≤ 30 cmH₂O to prevent
/// ventilator-induced lung injury (VILI / barotrauma).
@riverpod
double plateauPressure(PlateauPressureRef ref) {
  final p = ref.watch(ventParamsNotifierProvider);
  return p.peep + ref.watch(drivingPressureProvider);
}

/// Tidal Volume per kg of Ideal Body Weight (mL/kg IBW).
///
/// Lung-protective range: 6–8 mL/kg IBW (ARDSNet). Uses measured Vte
/// when available, otherwise the set Vt.
@riverpod
double vtPerKg(VtPerKgRef ref) {
  final p = ref.watch(ventParamsNotifierProvider);
  final metrics = ref.watch(cycleMetricsProvider);
  final ibw = ref.watch(ibwProvider);
  final vte = metrics.vte > 0 ? metrics.vte.toDouble() : p.vt.toDouble();
  return vte / ibw;
}

/// Mechanical Power (J/min) — simplified Gattinoni formula.
///
/// MP = 0.098 × RR × (Vt/1000) × (PIP − DP/2)
///
/// Quantifies the total energy delivered to the respiratory system per
/// minute. Threshold ≥ 17 J/min associated with increased VILI risk.
/// Uses measured PIP when available, otherwise the set PIP from VentParams.
@riverpod
double mechanicalPower(MechanicalPowerRef ref) {
  final p = ref.watch(ventParamsNotifierProvider);
  final dp = ref.watch(drivingPressureProvider);
  final metrics = ref.watch(cycleMetricsProvider);
  final pip = metrics.pip > 0 ? metrics.pip.toDouble() : p.pip;
  return 0.098 * p.rr * (p.vt / 1000.0) * (pip - dp / 2);
}
