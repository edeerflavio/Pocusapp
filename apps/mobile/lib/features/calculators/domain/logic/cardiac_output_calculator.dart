import 'dart:math' as math;

import '../constants/medical_guidelines.dart';
import '../entities/alert_level.dart';
import '../entities/calculation_result.dart';

const _id = 'dc';

/// Calculates Cardiac Output by Doppler VTI method (LVOT area × VTI × HR).
///
/// Steps:
///   1. LVOT cross-sectional area (cm²) = π × (D / 2)²
///   2. Stroke volume (mL)              = area × VTI
///   3. Cardiac output (L/min)          = (SV × HR) / 1000
///
/// Intermediate values (area, SV) are stored in the snapshot for transparency.
///
/// [lvotDiameter] — LVOT diameter in cm  (must be > 0)
/// [vti]          — LVOT VTI in cm       (must be > 0)
/// [heartRate]    — heart rate in bpm    (must be > 0)
CalculationResult calculateCardiacOutput({
  required double lvotDiameter,
  required double vti,
  required double heartRate,
}) {
  assert(lvotDiameter > 0, 'LVOT diameter must be positive');
  assert(vti > 0, 'VTI must be positive');
  assert(heartRate > 0, 'Heart rate must be positive');

  final area = math.pi * math.pow(lvotDiameter / 2, 2);
  final strokeVolume = area * vti;
  final cardiacOutput = (strokeVolume * heartRate) / 1000.0;

  final AlertLevel alert;
  if (cardiacOutput < MedicalGuidelines.dcNormalMin ||
      cardiacOutput > MedicalGuidelines.dcNormalMax) {
    alert = AlertLevel.warning;
  } else {
    alert = AlertLevel.normal;
  }

  return CalculationResult(
    calculatorId: _id,
    calculatorName: MedicalGuidelines.dcFullName,
    value: cardiacOutput,
    unit: MedicalGuidelines.dcUnit,
    alertLevel: alert,
    interpretation: MedicalGuidelines.dcInterpretation(cardiacOutput),
    inputSnapshot: {
      'lvot_diameter_cm': lvotDiameter,
      'vti_cm': vti,
      'heart_rate_bpm': heartRate,
      'lvot_area_cm2': area,
      'stroke_volume_ml': strokeVolume,
    },
    calculatedAt: DateTime.now(),
  );
}
