import '../constants/medical_guidelines.dart';
import '../entities/alert_level.dart';
import '../entities/calculation_result.dart';

const _id = 'rap';

/// Estimates Right Atrial Pressure from IVC diameter and inspiratory collapse.
///
/// Criteria (ACC/ASE guidelines):
/// - IVC ≤ 2.1 cm  AND  collapse > 50%  →  3 mmHg  (normal)
/// - IVC > 2.1 cm  AND  collapse < 50%  →  15 mmHg (elevated)
/// - All other combinations             →  8 mmHg  (intermediate)
///
/// [vciDiameter]    — IVC diameter in cm  (must be > 0)
/// [collapsePercent] — inspiratory collapse in %  (0–100)
CalculationResult calculateRap({
  required double vciDiameter,
  required double collapsePercent,
}) {
  assert(vciDiameter > 0, 'VCI diameter must be positive');
  assert(
    collapsePercent >= 0 && collapsePercent <= 100,
    'Collapse % must be between 0 and 100',
  );

  final double rap;

  if (vciDiameter <= MedicalGuidelines.rapVciSmallThreshold &&
      collapsePercent > MedicalGuidelines.rapCollapseHighThreshold) {
    rap = MedicalGuidelines.rapLow;
  } else if (vciDiameter > MedicalGuidelines.rapVciSmallThreshold &&
      collapsePercent < MedicalGuidelines.rapCollapseHighThreshold) {
    rap = MedicalGuidelines.rapHigh;
  } else {
    rap = MedicalGuidelines.rapIntermediate;
  }

  final alert =
      rap == MedicalGuidelines.rapHigh ? AlertLevel.warning : AlertLevel.normal;

  return CalculationResult(
    calculatorId: _id,
    calculatorName: MedicalGuidelines.rapFullName,
    value: rap,
    unit: MedicalGuidelines.rapUnit,
    alertLevel: alert,
    interpretation: MedicalGuidelines.rapInterpretation(rap),
    inputSnapshot: {
      'vci_diameter_cm': vciDiameter,
      'collapse_percent': collapsePercent,
    },
    calculatedAt: DateTime.now(),
  );
}
