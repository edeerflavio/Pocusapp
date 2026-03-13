import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/ventilator_entities.dart';
import '../../domain/services/abg_analyzer.dart';
import 'patient_provider.dart';
import 'ventilator_params_provider.dart';

part 'abg_provider.g.dart';

// ---------------------------------------------------------------------------
// AbgInputNotifier — manages the raw arterial blood gas values entered
// by the learner.
//
// Starts at textbook-normal values. Each setter emits a new immutable
// AbgInput snapshot.
// ---------------------------------------------------------------------------

@riverpod
class AbgInputNotifier extends _$AbgInputNotifier {
  @override
  AbgInput build() => AbgInput.initial();

  void updatePH(double v) => state = state.copyWith(ph: v);

  void updatePCO2(double v) => state = state.copyWith(pco2: v);

  void updateHCO3(double v) => state = state.copyWith(hco3: v);

  void updatePaO2(double v) => state = state.copyWith(pao2: v);

  void updateSaO2(double v) => state = state.copyWith(sao2: v);

  void updateLactato(double v) => state = state.copyWith(lactato: v);

  void reset() => state = AbgInput.initial();
}

// ---------------------------------------------------------------------------
// AbgAnalysisNotifier — holds the result of ABG interpretation.
//
// State is null until the user explicitly taps "Analisar". This avoids
// running the full clinical decision engine on every keystroke and gives
// the learner a clear "submit → feedback" interaction pattern.
// ---------------------------------------------------------------------------

@riverpod
class AbgAnalysisNotifier extends _$AbgAnalysisNotifier {
  @override
  AbgAnalysis? build() => null;

  /// Run the ABG analyser against the current inputs, ventilator
  /// parameters, and patient data. Updates state with the result.
  void analyze() {
    final abg = ref.read(abgInputNotifierProvider);
    final params = ref.read(ventParamsNotifierProvider);
    final patient = ref.read(patientNotifierProvider);

    state = AbgAnalyzer.analyze(
      abg: abg,
      ventParams: params,
      patient: patient,
    );
  }

  /// Clear the analysis result (e.g. when the user edits inputs).
  void clear() => state = null;
}
