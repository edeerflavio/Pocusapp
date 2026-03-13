import 'package:flutter_test/flutter_test.dart';

import 'package:pocusapp/features/simulator/domain/entities/ventilator_entities.dart';
import 'package:pocusapp/features/simulator/domain/services/blood_gas_engine.dart';

void main() {
  // ── Standard params/patient for most tests ──────────────────────────────
  const normalParams = VentParams(
    compliance: 50,
    resistance: 5,
    peep: 5,
    rr: 14,
    vt: 450,
    fio2: 21,
  );

  const normalPatient = PatientData(
    heightCm: 170,
    weightKg: 70,
    age: 50,
  );

  group('Alveolar Ventilation', () {
    test('normal params produce VA ≈ 4–6 L/min', () {
      final va = BloodGasEngine.alveolarVentilation(
        params: normalParams,
        patient: normalPatient,
      );
      // Vd ≈ 2.2 × 66 ≈ 145 mL, VA = (450-145) × 14 / 1000 ≈ 4.27
      expect(va, greaterThan(3.5));
      expect(va, lessThan(6.0));
    });

    test('higher RR increases VA', () {
      final vaLow = BloodGasEngine.alveolarVentilation(
        params: normalParams.copyWith(rr: 10),
        patient: normalPatient,
      );
      final vaHigh = BloodGasEngine.alveolarVentilation(
        params: normalParams.copyWith(rr: 20),
        patient: normalPatient,
      );
      expect(vaHigh, greaterThan(vaLow));
    });

    test('higher VT increases VA', () {
      final vaLow = BloodGasEngine.alveolarVentilation(
        params: normalParams.copyWith(vt: 300),
        patient: normalPatient,
      );
      final vaHigh = BloodGasEngine.alveolarVentilation(
        params: normalParams.copyWith(vt: 600),
        patient: normalPatient,
      );
      expect(vaHigh, greaterThan(vaLow));
    });
  });

  group('Target PaCO2', () {
    test('normal ventilation → PaCO₂ ≈ 35–45 mmHg', () {
      final target = BloodGasEngine.targetPaCO2(
        params: normalParams,
        patient: normalPatient,
      );
      expect(target, greaterThan(30));
      expect(target, lessThan(50));
    });

    test('hyperventilation → lower PaCO₂', () {
      final targetNormal = BloodGasEngine.targetPaCO2(
        params: normalParams,
        patient: normalPatient,
      );
      final targetHyper = BloodGasEngine.targetPaCO2(
        params: normalParams.copyWith(rr: 24, vt: 500),
        patient: normalPatient,
      );
      expect(targetHyper, lessThan(targetNormal));
    });

    test('hypoventilation → higher PaCO₂', () {
      final targetNormal = BloodGasEngine.targetPaCO2(
        params: normalParams,
        patient: normalPatient,
      );
      final targetHypo = BloodGasEngine.targetPaCO2(
        params: normalParams.copyWith(rr: 8, vt: 300),
        patient: normalPatient,
      );
      expect(targetHypo, greaterThan(targetNormal));
    });
  });

  group('CO₂ Washout (stepPaCO2)', () {
    test('PaCO₂ approaches target over time', () {
      // Start at 40, change to hyperventilation (target ~25)
      final hyperParams = normalParams.copyWith(rr: 24, vt: 550);
      double paco2 = 40.0;

      // Step for 90 seconds (should be close to target).
      for (int i = 0; i < 90; i++) {
        paco2 = BloodGasEngine.stepPaCO2(
          currentPaCO2: paco2,
          params: hyperParams,
          patient: normalPatient,
          dt: 1.0,
        );
      }

      final target = BloodGasEngine.targetPaCO2(
        params: hyperParams,
        patient: normalPatient,
      );
      expect((paco2 - target).abs(), lessThan(4.0));
    });

    test('washout takes ~30-60s to reach 80% of change', () {
      final hyperParams = normalParams.copyWith(rr: 24, vt: 550);
      final target = BloodGasEngine.targetPaCO2(
        params: hyperParams,
        patient: normalPatient,
      );
      final startPaCO2 = 40.0;
      final totalChange = target - startPaCO2;

      double paco2 = startPaCO2;
      // Step for 45 seconds.
      for (int i = 0; i < 45; i++) {
        paco2 = BloodGasEngine.stepPaCO2(
          currentPaCO2: paco2,
          params: hyperParams,
          patient: normalPatient,
          dt: 1.0,
        );
      }

      final achieved = paco2 - startPaCO2;
      final fraction = achieved / totalChange;

      // At t=τ (45s), should be ~63% of the way (1 - 1/e ≈ 0.632).
      expect(fraction, greaterThan(0.55));
      expect(fraction, lessThan(0.75));
    });

    test('no change when already at target', () {
      final paco2Before = BloodGasEngine.targetPaCO2(
        params: normalParams,
        patient: normalPatient,
      );
      final paco2After = BloodGasEngine.stepPaCO2(
        currentPaCO2: paco2Before,
        params: normalParams,
        patient: normalPatient,
        dt: 1.0,
      );
      expect((paco2After - paco2Before).abs(), lessThan(0.01));
    });
  });

  group('Oxygenation (computePaO2)', () {
    test('room air + normal lung → PaO₂ 80–110 mmHg', () {
      final pao2 = BloodGasEngine.computePaO2(
        params: normalParams,
        patient: normalPatient,
        paco2: 40.0,
      );
      expect(pao2, greaterThan(70));
      expect(pao2, lessThan(120));
    });

    test('high FiO₂ → higher PaO₂', () {
      final pao2Low = BloodGasEngine.computePaO2(
        params: normalParams.copyWith(fio2: 21),
        patient: normalPatient,
        paco2: 40.0,
      );
      final pao2High = BloodGasEngine.computePaO2(
        params: normalParams.copyWith(fio2: 60),
        patient: normalPatient,
        paco2: 40.0,
      );
      expect(pao2High, greaterThan(pao2Low));
    });

    test('low compliance → lower PaO₂ (shunt model)', () {
      final pao2Normal = BloodGasEngine.computePaO2(
        params: normalParams,
        patient: normalPatient,
        paco2: 40.0,
      );
      final pao2Ards = BloodGasEngine.computePaO2(
        params: normalParams.copyWith(compliance: 20, fio2: 21),
        patient: normalPatient,
        paco2: 40.0,
      );
      expect(pao2Ards, lessThan(pao2Normal));
    });

    test('PEEP improves PaO₂ in low-compliance scenario', () {
      final ardsParams = normalParams.copyWith(compliance: 20, fio2: 50);
      final pao2LowPeep = BloodGasEngine.computePaO2(
        params: ardsParams.copyWith(peep: 5),
        patient: normalPatient,
        paco2: 40.0,
      );
      final pao2HighPeep = BloodGasEngine.computePaO2(
        params: ardsParams.copyWith(peep: 14),
        patient: normalPatient,
        paco2: 40.0,
      );
      expect(pao2HighPeep, greaterThan(pao2LowPeep));
    });
  });

  group('SaO₂ (Hill equation)', () {
    test('PaO₂ = 100 → SaO₂ ≈ 97–99%', () {
      final sao2 = BloodGasEngine.computeSaO2(100);
      expect(sao2, greaterThan(96));
      expect(sao2, lessThan(100));
    });

    test('PaO₂ = 60 → SaO₂ ≈ 88–92%', () {
      final sao2 = BloodGasEngine.computeSaO2(60);
      expect(sao2, greaterThan(86));
      expect(sao2, lessThan(94));
    });

    test('PaO₂ = 27 → SaO₂ ≈ 50% (P50)', () {
      final sao2 = BloodGasEngine.computeSaO2(26.6);
      expect(sao2, closeTo(50, 2));
    });
  });

  group('pH (Henderson-Hasselbalch)', () {
    test('normal PaCO₂ + HCO₃ → pH ≈ 7.40', () {
      final ph = BloodGasEngine.computePH(paco2: 40, hco3: 24);
      expect(ph, closeTo(7.40, 0.02));
    });

    test('high PaCO₂ → lower pH (respiratory acidosis)', () {
      final ph = BloodGasEngine.computePH(paco2: 60, hco3: 24);
      expect(ph, lessThan(7.35));
    });

    test('low PaCO₂ → higher pH (respiratory alkalosis)', () {
      final ph = BloodGasEngine.computePH(paco2: 25, hco3: 24);
      expect(ph, greaterThan(7.45));
    });

    test('low HCO₃ → lower pH (metabolic acidosis)', () {
      final ph = BloodGasEngine.computePH(paco2: 40, hco3: 15);
      expect(ph, lessThan(7.35));
    });
  });

  group('HCO₃ compensation (stepHCO3)', () {
    test('HCO₃ drifts toward compensated value very slowly', () {
      // Start at 24, with PaCO₂ = 60 (respiratory acidosis).
      // Acute compensation target: 24 + (60-40)*0.1 = 26.
      double hco3 = 24.0;

      // Step for 60 seconds — should barely move (τ = 3600s).
      for (int i = 0; i < 60; i++) {
        hco3 = BloodGasEngine.stepHCO3(
          currentHCO3: hco3,
          paco2: 60,
          dt: 1.0,
        );
      }

      // Should move only slightly toward 26.
      expect(hco3, greaterThan(24.0));
      expect(hco3, lessThan(24.5)); // Very small change in 60s.
    });
  });

  group('RSBI (Tobin Index)', () {
    test('RR=20, Vte=400mL → RSBI = 50 (favorable)', () {
      final rsbi = BloodGasEngine.rsbi(rr: 20, vte: 400);
      expect(rsbi, closeTo(50, 1));
    });

    test('RR=35, Vte=200mL → RSBI = 175 (unfavorable)', () {
      final rsbi = BloodGasEngine.rsbi(rr: 35, vte: 200);
      expect(rsbi, closeTo(175, 1));
    });

    test('Vte=0 → RSBI = 999 (safety)', () {
      final rsbi = BloodGasEngine.rsbi(rr: 20, vte: 0);
      expect(rsbi, 999.0);
    });
  });

  group('Weaning Assessment', () {
    test('ideal PSV patient passes all criteria', () {
      final assessment = BloodGasEngine.assessWeaning(
        params: const VentParams(
          peep: 5,
          fio2: 30,
          rr: 14,
          vt: 450,
          ps: 8,
        ),
        metrics: const CycleMetrics(pip: 13, peep: 5, vte: 450, rr: 16),
        pao2: 95,
        paco2: 38,
        ph: 7.40,
      );

      expect(assessment.readyToWean, isTrue);
      expect(assessment.passedCount, assessment.totalCount);
    });

    test('high PEEP + high FiO₂ fails weaning criteria', () {
      final assessment = BloodGasEngine.assessWeaning(
        params: const VentParams(
          peep: 14,
          fio2: 70,
          rr: 22,
          vt: 350,
        ),
        metrics: const CycleMetrics(pip: 28, peep: 14, vte: 350, rr: 22),
        pao2: 70,
        paco2: 50,
        ph: 7.32,
      );

      expect(assessment.readyToWean, isFalse);
      expect(assessment.passedCount, lessThan(assessment.totalCount));
    });
  });

  group('Full snapshot (computeSnapshot)', () {
    test('normal params produce physiological ABG', () {
      final result = BloodGasEngine.computeSnapshot(
        paco2: 40.0,
        hco3: 24.0,
        params: normalParams,
        patient: normalPatient,
      );

      expect(result.ph, closeTo(7.40, 0.03));
      expect(result.paco2, 40.0);
      expect(result.pao2, greaterThan(70));
      expect(result.hco3, 24.0);
      expect(result.sao2, greaterThan(95));
      expect(result.pfRatio, greaterThan(300));
      expect(result.alveolarVentilation, greaterThan(3.5));
      expect(result.minuteVolume, greaterThan(5));
    });
  });
}
