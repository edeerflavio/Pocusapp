import '../constants/medical_guidelines.dart';
import '../entities/alert_level.dart';
import '../entities/calculation_result.dart';

const _id = 'epss';

/// Evaluates E-Point Septal Separation for LV systolic function estimation.
///
/// The threshold is configurable — the default (7 mm) follows Silverstein 2006.
/// Custom thresholds are stored in the snapshot for full reproducibility.
///
/// [epss]      — measured EPSS value in mm   (must be ≥ 0)
/// [threshold] — abnormal cut-off in mm      (must be > 0; default 7 mm)
CalculationResult calculateEpss({
  required double epss,
  double threshold = MedicalGuidelines.epssWarningThreshold,
}) {
  assert(epss >= 0, 'EPSS must be non-negative');
  assert(threshold > 0, 'Threshold must be positive');

  final alert = epss > threshold ? AlertLevel.warning : AlertLevel.normal;

  return CalculationResult(
    calculatorId: _id,
    calculatorName: MedicalGuidelines.epssFullName,
    value: epss,
    unit: MedicalGuidelines.epssUnit,
    alertLevel: alert,
    interpretation:
        MedicalGuidelines.epssInterpretation(epss, threshold: threshold),
    inputSnapshot: {
      'epss_mm': epss,
      'threshold_mm': threshold,
    },
    calculatedAt: DateTime.now(),
  );
}
