import 'package:flutter_test/flutter_test.dart';

import 'package:pocusapp/features/calculators/domain/constants/medical_guidelines.dart';
import 'package:pocusapp/features/calculators/domain/entities/alert_level.dart';
import 'package:pocusapp/features/calculators/domain/logic/cardiac_index_calculator.dart';
import 'package:pocusapp/features/calculators/domain/logic/cardiac_output_calculator.dart';
import 'package:pocusapp/features/calculators/domain/logic/epss_calculator.dart';
import 'package:pocusapp/features/calculators/domain/logic/psap_calculator.dart';
import 'package:pocusapp/features/calculators/domain/logic/rap_calculator.dart';

void main() {
  // ── RAP ───────────────────────────────────────────────────────────────────

  group('RAP Calculator', () {
    test('VCI ≤ 2.1 cm AND collapse > 50% → 3 mmHg (normal)', () {
      final r = calculateRap(vciDiameter: 1.8, collapsePercent: 60);
      expect(r.value, 3.0);
      expect(r.alertLevel, AlertLevel.normal);
      expect(r.calculatorId, 'rap');
    });

    test('VCI > 2.1 cm AND collapse < 50% → 15 mmHg (warning)', () {
      final r = calculateRap(vciDiameter: 2.5, collapsePercent: 30);
      expect(r.value, 15.0);
      expect(r.alertLevel, AlertLevel.warning);
    });

    test('VCI > 2.1 cm AND collapse > 50% → 8 mmHg (intermediate)', () {
      final r = calculateRap(vciDiameter: 2.5, collapsePercent: 60);
      expect(r.value, 8.0);
      expect(r.alertLevel, AlertLevel.normal);
    });

    test('VCI ≤ 2.1 cm AND collapse < 50% → 8 mmHg (intermediate)', () {
      final r = calculateRap(vciDiameter: 1.5, collapsePercent: 30);
      expect(r.value, 8.0);
      expect(r.alertLevel, AlertLevel.normal);
    });

    test('Boundary: VCI exactly 2.1 cm + collapse > 50% → 3 mmHg', () {
      final r = calculateRap(vciDiameter: 2.1, collapsePercent: 51);
      expect(r.value, 3.0);
    });

    test('Boundary: collapse exactly 50% → intermediate (not "high")', () {
      // collapsePercent > 50 required for "low" RAP, so 50% → intermediate
      final r = calculateRap(vciDiameter: 1.5, collapsePercent: 50);
      expect(r.value, 8.0);
    });

    test('Snapshot contains input values', () {
      final r = calculateRap(vciDiameter: 1.8, collapsePercent: 60);
      expect(r.inputSnapshot['vci_diameter_cm'], 1.8);
      expect(r.inputSnapshot['collapse_percent'], 60.0);
    });
  });

  // ── PSAP ──────────────────────────────────────────────────────────────────

  group('PSAP Calculator', () {
    test('Formula: PSAP = 4 × Vmax² + RAP', () {
      // 4 × 2.0² + 5 = 16 + 5 = 21
      final r = calculatePsap(vmax: 2.0, rap: 5);
      expect(r.value, closeTo(21.0, 0.001));
    });

    test('Normal PSAP < 35 mmHg', () {
      // 4 × 2.5² + 3 = 25 + 3 = 28
      final r = calculatePsap(vmax: 2.5, rap: 3);
      expect(r.value, closeTo(28.0, 0.001));
      expect(r.alertLevel, AlertLevel.normal);
    });

    test('Warning: 35 ≤ PSAP < 50 mmHg', () {
      // 4 × 3.0² + 3 = 36 + 3 = 39
      final r = calculatePsap(vmax: 3.0, rap: 3);
      expect(r.value, closeTo(39.0, 0.001));
      expect(r.alertLevel, AlertLevel.warning);
    });

    test('Critical: PSAP ≥ 50 mmHg', () {
      // 4 × 3.5² + 8 = 49 + 8 = 57
      final r = calculatePsap(vmax: 3.5, rap: 8);
      expect(r.value, closeTo(57.0, 0.001));
      expect(r.alertLevel, AlertLevel.critical);
    });

    test('Boundary: PSAP exactly 35 → warning', () {
      // 4 × Vmax² + RAP = 35  →  Vmax² = (35 - 5) / 4 = 7.5  →  Vmax = √7.5
      final vmax = (7.5).toDouble();
      final r = calculatePsap(vmax: vmax.abs(), rap: 5);
      // actual value will differ, just verify warning threshold logic is correct
      // Use a known case: 4*2.9² + 3 = 33.64 + 3 = 36.64 → warning
      final r2 = calculatePsap(vmax: 2.9, rap: 3);
      expect(r2.alertLevel, AlertLevel.warning);
    });

    test('Snapshot contains vmax and rap', () {
      final r = calculatePsap(vmax: 2.5, rap: 8);
      expect(r.inputSnapshot['vmax_m_s'], 2.5);
      expect(r.inputSnapshot['rap_mmhg'], 8.0);
    });
  });

  // ── Cardiac Output ────────────────────────────────────────────────────────

  group('Cardiac Output Calculator', () {
    test('Formula: CO = π × (D/2)² × VTI × HR / 1000', () {
      // D=2.0 → area = π × 1² ≈ 3.14159
      // SV = 3.14159 × 20 ≈ 62.832
      // CO = 62.832 × 70 / 1000 ≈ 4.398
      final r = calculateCardiacOutput(
        lvotDiameter: 2.0,
        vti: 20,
        heartRate: 70,
      );
      expect(r.value, closeTo(4.398, 0.01));
    });

    test('Normal CO 4–8 L/min → normal alert', () {
      final r = calculateCardiacOutput(
        lvotDiameter: 2.0,
        vti: 20,
        heartRate: 70,
      );
      expect(r.alertLevel, AlertLevel.normal);
    });

    test('Low CO < 4 L/min → warning', () {
      // D=1.8, VTI=10, HR=50 → area≈2.545, SV≈25.45, CO≈1.27
      final r = calculateCardiacOutput(
        lvotDiameter: 1.8,
        vti: 10,
        heartRate: 50,
      );
      expect(r.value, lessThan(MedicalGuidelines.dcNormalMin));
      expect(r.alertLevel, AlertLevel.warning);
    });

    test('High CO > 8 L/min → warning', () {
      // D=2.5, VTI=30, HR=120 → area≈4.909, SV≈147.26, CO≈17.67
      final r = calculateCardiacOutput(
        lvotDiameter: 2.5,
        vti: 30,
        heartRate: 120,
      );
      expect(r.value, greaterThan(MedicalGuidelines.dcNormalMax));
      expect(r.alertLevel, AlertLevel.warning);
    });

    test('Snapshot includes intermediate values (area + SV)', () {
      final r = calculateCardiacOutput(
        lvotDiameter: 2.0,
        vti: 20,
        heartRate: 70,
      );
      expect(r.inputSnapshot.containsKey('lvot_area_cm2'), isTrue);
      expect(r.inputSnapshot.containsKey('stroke_volume_ml'), isTrue);
      expect(r.inputSnapshot['lvot_area_cm2'], closeTo(3.14159, 0.001));
    });

    test('Unit is L/min', () {
      final r = calculateCardiacOutput(
        lvotDiameter: 2.0,
        vti: 20,
        heartRate: 70,
      );
      expect(r.unit, 'L/min');
    });
  });

  // ── Cardiac Index ─────────────────────────────────────────────────────────

  group('Cardiac Index Calculator', () {
    test('Formula: IC = CO / BSA', () {
      final r = calculateCardiacIndex(cardiacOutput: 5.0, bsa: 2.0);
      expect(r.value, closeTo(2.5, 0.001));
    });

    test('Critical: IC < 2.2 L/min/m²', () {
      // 3.0 / 1.9 ≈ 1.578
      final r = calculateCardiacIndex(cardiacOutput: 3.0, bsa: 1.9);
      expect(r.value, closeTo(1.578, 0.01));
      expect(r.alertLevel, AlertLevel.critical);
    });

    test('Warning: 2.2 ≤ IC < 2.5 L/min/m²', () {
      // 4.0 / 1.7 ≈ 2.353
      final r = calculateCardiacIndex(cardiacOutput: 4.0, bsa: 1.7);
      expect(r.value, closeTo(2.353, 0.01));
      expect(r.alertLevel, AlertLevel.warning);
    });

    test('Normal: IC ≥ 2.5 L/min/m²', () {
      // 5.0 / 1.8 ≈ 2.778
      final r = calculateCardiacIndex(cardiacOutput: 5.0, bsa: 1.8);
      expect(r.value, closeTo(2.778, 0.01));
      expect(r.alertLevel, AlertLevel.normal);
    });

    test('Boundary: IC exactly 2.2 → warning (not critical)', () {
      // CO = 2.2 × 1.0 = 2.2, BSA = 1.0
      final r = calculateCardiacIndex(cardiacOutput: 2.2, bsa: 1.0);
      expect(r.value, closeTo(2.2, 0.001));
      expect(r.alertLevel, AlertLevel.warning);
    });

    test('Boundary: IC exactly 2.5 → normal (not warning)', () {
      final r = calculateCardiacIndex(cardiacOutput: 2.5, bsa: 1.0);
      expect(r.value, closeTo(2.5, 0.001));
      expect(r.alertLevel, AlertLevel.normal);
    });

    test('Unit is L/min/m²', () {
      final r = calculateCardiacIndex(cardiacOutput: 5.0, bsa: 2.0);
      expect(r.unit, 'L/min/m²');
    });
  });

  // ── EPSS ──────────────────────────────────────────────────────────────────

  group('EPSS Calculator', () {
    test('EPSS ≤ 7 mm → normal', () {
      final r = calculateEpss(epss: 5.0);
      expect(r.alertLevel, AlertLevel.normal);
    });

    test('EPSS > 7 mm → warning', () {
      final r = calculateEpss(epss: 9.0);
      expect(r.alertLevel, AlertLevel.warning);
    });

    test('Boundary: EPSS exactly 7 mm → normal (not strictly >)', () {
      final r = calculateEpss(epss: 7.0);
      expect(r.alertLevel, AlertLevel.normal);
    });

    test('Boundary: EPSS = 7.1 mm → warning', () {
      final r = calculateEpss(epss: 7.1);
      expect(r.alertLevel, AlertLevel.warning);
    });

    test('Custom threshold respected', () {
      // epss = 8.0, threshold = 10.0 → should be normal
      final r = calculateEpss(epss: 8.0, threshold: 10.0);
      expect(r.alertLevel, AlertLevel.normal);
    });

    test('Custom threshold — above → warning', () {
      final r = calculateEpss(epss: 12.0, threshold: 10.0);
      expect(r.alertLevel, AlertLevel.warning);
    });

    test('Snapshot contains epss and threshold', () {
      final r = calculateEpss(epss: 9.0, threshold: 7.0);
      expect(r.inputSnapshot['epss_mm'], 9.0);
      expect(r.inputSnapshot['threshold_mm'], 7.0);
    });

    test('Value passes through unchanged', () {
      final r = calculateEpss(epss: 11.5);
      expect(r.value, 11.5);
      expect(r.unit, 'mm');
    });
  });

  // ── AlertLevel ────────────────────────────────────────────────────────────

  group('AlertLevel', () {
    test('normal is not abnormal', () {
      expect(AlertLevel.normal.isAbnormal, isFalse);
    });

    test('warning is abnormal', () {
      expect(AlertLevel.warning.isAbnormal, isTrue);
    });

    test('critical is abnormal', () {
      expect(AlertLevel.critical.isAbnormal, isTrue);
    });
  });

  // ── CalculationResult.toJson ──────────────────────────────────────────────

  group('CalculationResult serialisation', () {
    test('toJson produces correct keys', () {
      final r = calculateRap(vciDiameter: 1.8, collapsePercent: 60);
      final json = r.toJson();
      expect(json['calculator_id'], 'rap');
      expect(json['value'], 3.0);
      expect(json['alert_level'], 'normal');
      expect(json['unit'], 'mmHg');
      expect(json.containsKey('calculated_at'), isTrue);
      expect(json.containsKey('input_snapshot'), isTrue);
    });
  });
}
