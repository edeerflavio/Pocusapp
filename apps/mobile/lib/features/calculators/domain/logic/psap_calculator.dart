import '../constants/medical_guidelines.dart';
import '../entities/alert_level.dart';
import '../entities/calculation_result.dart';

const _id = 'psap';

/// Calculates Pulmonary Systolic Arterial Pressure via simplified Bernoulli.
///
/// Formula: PSAP = (4 × Vmax²) + RAP
///
/// Alert levels:
/// - Normal   : PSAP < 35 mmHg
/// - Warning  : 35 ≤ PSAP < 50 mmHg
/// - Critical : PSAP ≥ 50 mmHg
///
/// [vmax] — peak tricuspid regurgitation velocity in m/s  (must be > 0)
/// [rap]  — right atrial pressure in mmHg                 (must be ≥ 0)
CalculationResult calculatePsap({
  required double vmax,
  required double rap,
}) {
  assert(vmax > 0, 'Vmax must be positive');
  assert(rap >= 0, 'RAP must be non-negative');

  final psap = (4 * vmax * vmax) + rap;

  final AlertLevel alert;
  if (psap >= MedicalGuidelines.psapCriticalThreshold) {
    alert = AlertLevel.critical;
  } else if (psap >= MedicalGuidelines.psapWarningThreshold) {
    alert = AlertLevel.warning;
  } else {
    alert = AlertLevel.normal;
  }

  return CalculationResult(
    calculatorId: _id,
    calculatorName: MedicalGuidelines.psapFullName,
    value: psap,
    unit: MedicalGuidelines.psapUnit,
    alertLevel: alert,
    interpretation: MedicalGuidelines.psapInterpretation(psap),
    inputSnapshot: {
      'vmax_m_s': vmax,
      'rap_mmhg': rap,
    },
    calculatedAt: DateTime.now(),
  );
}
