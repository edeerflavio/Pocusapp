import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/ventilator_entities.dart';
import '../../domain/enums/ventilation_enums.dart';

part 'patient_provider.g.dart';

// ---------------------------------------------------------------------------
// PatientNotifier — manages patient anthropometric data.
//
// State is used to compute IBW, BMI, and protective Vt range. Changes
// automatically propagate to derived providers (ibw, bmi) and any
// downstream consumer (e.g. AbgAnalyzer).
// ---------------------------------------------------------------------------

@riverpod
class PatientNotifier extends _$PatientNotifier {
  @override
  PatientData build() => PatientData.initial();

  void updateHeight(int cm) => state = state.copyWith(heightCm: cm);

  void updateWeight(int kg) => state = state.copyWith(weightKg: kg);

  void updateAge(int years) => state = state.copyWith(age: years);

  void updateSex(Sex sex) => state = state.copyWith(sex: sex);

  void reset() => state = PatientData.initial();
}

// ---------------------------------------------------------------------------
// Derived read-only providers — recalculate when patient data changes.
// ---------------------------------------------------------------------------

/// Ideal Body Weight (kg) — ARDSNet / Devine formula.
@riverpod
double ibw(IbwRef ref) => ref.watch(patientNotifierProvider).ibw;

/// Body Mass Index (kg/m²).
@riverpod
double bmi(BmiRef ref) => ref.watch(patientNotifierProvider).bmi;

/// Lower bound of protective tidal volume: 6 mL/kg IBW (mL).
@riverpod
int idealVt6(IdealVt6Ref ref) => ref.watch(patientNotifierProvider).idealVt6;

/// Upper bound of protective tidal volume: 8 mL/kg IBW (mL).
@riverpod
int idealVt8(IdealVt8Ref ref) => ref.watch(patientNotifierProvider).idealVt8;
