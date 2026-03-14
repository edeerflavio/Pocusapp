import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/services/blood_gas_engine.dart';
import 'patient_provider.dart';
import 'simulation_provider.dart';
import 'ventilator_params_provider.dart';

part 'blood_gas_lab_provider.g.dart';

// ═══════════════════════════════════════════════════════════════════════════
// BloodGasLabNotifier — manages dynamic ABG state with CO₂ washout
// ═══════════════════════════════════════════════════════════════════════════

/// State for the dynamic blood gas laboratory.
///
/// [livePaCO2] and [liveHCO3] track the continuously evolving values
/// (CO₂ washout model). [lastResult] holds the most recent "lab result"
/// that is frozen when the user taps "Solicitar Gasometria".
///
/// [pendingResult] is true during the simulated lab delay.
class BloodGasLabState {
  const BloodGasLabState({
    required this.livePaCO2,
    required this.liveHCO3,
    this.lastResult,
    this.pendingResult = false,
    this.resultCount = 0,
  });

  factory BloodGasLabState.initial() => const BloodGasLabState(
        livePaCO2: 40.0,
        liveHCO3: 24.0,
      );

  /// Current live PaCO₂ evolving via CO₂ washout (mmHg).
  final double livePaCO2;

  /// Current live HCO₃ evolving via slow renal compensation (mEq/L).
  final double liveHCO3;

  /// The most recent frozen lab result (null before first request).
  final DynamicAbgResult? lastResult;

  /// Whether a lab result is currently being "processed".
  final bool pendingResult;

  /// Total number of results delivered (for tracking).
  final int resultCount;

  BloodGasLabState copyWith({
    double? livePaCO2,
    double? liveHCO3,
    DynamicAbgResult? Function()? lastResult,
    bool? pendingResult,
    int? resultCount,
  }) =>
      BloodGasLabState(
        livePaCO2: livePaCO2 ?? this.livePaCO2,
        liveHCO3: liveHCO3 ?? this.liveHCO3,
        lastResult: lastResult != null ? lastResult() : this.lastResult,
        pendingResult: pendingResult ?? this.pendingResult,
        resultCount: resultCount ?? this.resultCount,
      );
}

@Riverpod(keepAlive: true)
class BloodGasLabNotifier extends _$BloodGasLabNotifier {
  @override
  BloodGasLabState build() => BloodGasLabState.initial();

  /// Advance the CO₂ washout and HCO₃ compensation by [dt] seconds.
  ///
  /// Called from the simulation tick (every frame). The internal PaCO₂
  /// and HCO₃ evolve continuously, but the UI only sees the frozen
  /// [lastResult] until a new gasometry is requested.
  void tick(double dt) {
    final params = ref.read(ventParamsNotifierProvider);
    final patient = ref.read(patientNotifierProvider);

    final newPaCO2 = BloodGasEngine.stepPaCO2(
      currentPaCO2: state.livePaCO2,
      params: params,
      patient: patient,
      dt: dt,
    );

    final newHCO3 = BloodGasEngine.stepHCO3(
      currentHCO3: state.liveHCO3,
      paco2: newPaCO2,
      dt: dt,
    );

    state = state.copyWith(livePaCO2: newPaCO2, liveHCO3: newHCO3);
  }

  /// Request a new gasometry — simulates lab processing delay.
  ///
  /// Sets [pendingResult] to true, waits 3 seconds (simulated draw +
  /// analyser time), then freezes a snapshot of the current dynamic
  /// ABG values into [lastResult].
  Future<void> requestGasometry() async {
    if (state.pendingResult) return; // Prevent double-request.

    state = state.copyWith(pendingResult: true);

    // Simulated lab processing delay (3 seconds).
    await Future<void>.delayed(const Duration(seconds: 3));

    final params = ref.read(ventParamsNotifierProvider);
    final patient = ref.read(patientNotifierProvider);

    final result = BloodGasEngine.computeSnapshot(
      paco2: state.livePaCO2,
      hco3: state.liveHCO3,
      params: params,
      patient: patient,
    );

    state = state.copyWith(
      pendingResult: false,
      lastResult: () => result,
      resultCount: state.resultCount + 1,
    );
  }

  /// Reset to initial state (e.g. on simulation reset).
  void reset() => state = BloodGasLabState.initial();
}

// ═══════════════════════════════════════════════════════════════════════════
// Derived providers
// ═══════════════════════════════════════════════════════════════════════════

/// Live (unfrozen) ABG preview — computed every frame for the real-time
/// display. Shows what the next gasometry would return if requested now.
@riverpod
DynamicAbgResult liveAbgPreview(LiveAbgPreviewRef ref) {
  final labState = ref.watch(bloodGasLabNotifierProvider);
  final params = ref.watch(ventParamsNotifierProvider);
  final patient = ref.watch(patientNotifierProvider);

  return BloodGasEngine.computeSnapshot(
    paco2: labState.livePaCO2,
    hco3: labState.liveHCO3,
    params: params,
    patient: patient,
  );
}

/// Weaning assessment — only meaningful in PSV mode.
///
/// Watches simulation metrics + live ABG to evaluate readiness.
@riverpod
WeaningAssessment weaningAssessment(WeaningAssessmentRef ref) {
  final params = ref.watch(ventParamsNotifierProvider);
  final metrics = ref.watch(cycleMetricsProvider);
  final preview = ref.watch(liveAbgPreviewProvider);

  return BloodGasEngine.assessWeaning(
    params: params,
    metrics: metrics,
    pao2: preview.pao2,
    paco2: preview.paco2,
    ph: preview.ph,
  );
}
