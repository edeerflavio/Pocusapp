import '../constants/medical_guidelines.dart';
import '../entities/alert_level.dart';
import '../entities/calculation_result.dart';

const _id = 'ic';

/// Calculates Cardiac Index by normalising CO to body surface area.
///
/// Formula: IC = DC (L/min) / BSA (m²)
///
/// Alert levels:
/// - Normal   : IC ≥ 2.5 L/min/m²
/// - Warning  : 2.2 ≤ IC < 2.5 L/min/m²
/// - Critical : IC < 2.2 L/min/m²  (cardiogenic shock risk)
///
/// [cardiacOutput] — cardiac output in L/min  (must be > 0)
/// [bsa]           — body surface area in m²  (must be > 0)
CalculationResult calculateCardiacIndex({
  required double cardiacOutput,
  required double bsa,
}) {
  assert(cardiacOutput > 0, 'Cardiac output must be positive');
  assert(bsa > 0, 'BSA must be positive');

  final cardiacIndex = cardiacOutput / bsa;

  final AlertLevel alert;
  if (cardiacIndex < MedicalGuidelines.icCriticalThreshold) {
    alert = AlertLevel.critical;
  } else if (cardiacIndex < MedicalGuidelines.icWarningThreshold) {
    alert = AlertLevel.warning;
  } else {
    alert = AlertLevel.normal;
  }

  return CalculationResult(
    calculatorId: _id,
    calculatorName: MedicalGuidelines.icFullName,
    value: cardiacIndex,
    unit: MedicalGuidelines.icUnit,
    alertLevel: alert,
    interpretation: MedicalGuidelines.icInterpretation(cardiacIndex),
    inputSnapshot: {
      'cardiac_output_l_min': cardiacOutput,
      'bsa_m2': bsa,
    },
    calculatedAt: DateTime.now(),
  );
}
