import 'package:flutter_test/flutter_test.dart';

import 'package:pocusapp/features/simulator/domain/entities/ventilator_entities.dart';
import 'package:pocusapp/features/simulator/domain/enums/ventilation_enums.dart';
import 'package:pocusapp/features/simulator/domain/services/abg_analyzer.dart';

void main() {
  // ── Default baseline values ────────────────────────────────────────────

  const normalAbg = AbgInput(
    ph: 7.40,
    pco2: 40,
    hco3: 24,
    pao2: 95,
    sao2: 97,
    lactato: 1.0,
  );

  const defaultVent = VentParams(
    vt: 420,
    rr: 14,
    peep: 5,
    fio2: 40,
    compliance: 50,
    resistance: 8,
  );

  const defaultPatient = PatientData(
    sex: Sex.male,
    heightCm: 170,
    weightKg: 70,
  );

  // Helper: run analyze with overrides.
  AbgAnalysis run({
    AbgInput? abg,
    VentParams? vent,
    PatientData? patient,
  }) =>
      AbgAnalyzer.analyze(
        abg: abg ?? normalAbg,
        ventParams: vent ?? defaultVent,
        patient: patient ?? defaultPatient,
      );

  // ═════════════════════════════════════════════════════════════════════════
  // Derived metrics
  // ═════════════════════════════════════════════════════════════════════════

  group('Derived metrics', () {
    test('P/F ratio = PaO₂ / (FiO₂/100)', () {
      final result = run();
      // 95 / 0.40 = 237.5
      expect(result.pfRatio, closeTo(237.5, 0.1));
    });

    test('driving pressure = Vt / compliance', () {
      final result = run();
      // 420 / 50 = 8.4
      expect(result.drivingPressure, closeTo(8.4, 0.1));
    });

    test('Pplat = PEEP + DP', () {
      final result = run();
      // 5 + 8.4 = 13.4
      expect(result.pplat, closeTo(13.4, 0.1));
    });

    test('Vt/kg = Vt / IBW', () {
      final result = run();
      final ibw = defaultPatient.ibw;
      expect(result.vtPerKg, closeTo(420 / ibw, 0.1));
    });

    test('minute volume = Vt × RR / 1000', () {
      final result = run();
      expect(result.minuteVolume, closeTo(420 * 14 / 1000.0, 0.01));
    });

    test('alveolar ventilation = (Vt - Vd) × RR / 1000', () {
      final result = run();
      final ibw = defaultPatient.ibw;
      final vd = 2.2 * ibw;
      final expected = (420 - vd) * 14 / 1000.0;
      expect(result.alveolarVentilation, closeTo(expected, 0.01));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Normal ABG
  // ═════════════════════════════════════════════════════════════════════════

  group('Normal ABG', () {
    test('primary disorder is "Equilíbrio ácido-base normal"', () {
      final result = run();
      expect(result.primaryDisorder, 'Equilíbrio ácido-base normal');
    });

    test('findings contain pH normal', () {
      final result = run();
      expect(
        result.findings.any((f) => f.text.contains('7.40')),
        isTrue,
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Acidose respiratória
  // ═════════════════════════════════════════════════════════════════════════

  group('Acidose respiratória', () {
    test('pH < 7.35 + PCO₂ > 45 → acidose respiratória', () {
      final result = run(
        abg: const AbgInput(ph: 7.28, pco2: 55, hco3: 24, pao2: 90),
      );
      expect(result.primaryDisorder, contains('Acidose respiratória'));
    });

    test('pH < 7.20 → acidose respiratória GRAVE + urgent actions', () {
      final result = run(
        abg: const AbgInput(ph: 7.15, pco2: 70, hco3: 24, pao2: 85),
      );
      expect(result.primaryDisorder, contains('grave'));
      expect(
        result.findings.any(
            (f) => f.level == AlertLevel.danger && f.text.contains('URGENTE')),
        isTrue,
      );
      // Should have priority 0 actions
      expect(result.actions.any((a) => a.priority == 0), isTrue);
    });

    test('recommends FR increase when RR < 30 and DP ≤ 15', () {
      final result = run(
        abg: const AbgInput(ph: 7.30, pco2: 50, hco3: 24, pao2: 90),
        vent: defaultVent.copyWith(rr: 14),
      );
      expect(
        result.actions.any((a) => a.param == 'FR' && a.action.contains('Aumentar')),
        isTrue,
      );
    });

    test('prefers FR over VT when DP > 15', () {
      // Low compliance → high DP
      final result = run(
        abg: const AbgInput(ph: 7.30, pco2: 50, hco3: 24, pao2: 90),
        vent: defaultVent.copyWith(compliance: 20, vt: 400),
        // DP = 400/20 = 20 > 15
      );
      expect(
        result.actions.any((a) => a.reason.contains('DP') ||
            (a.param == 'FR' && a.action.contains('Preferir'))),
        isTrue,
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Acidose metabólica
  // ═════════════════════════════════════════════════════════════════════════

  group('Acidose metabólica', () {
    test('pH < 7.35 + HCO₃ < 22 → acidose metabólica', () {
      final result = run(
        abg: const AbgInput(ph: 7.30, pco2: 30, hco3: 16, pao2: 90),
      );
      expect(result.primaryDisorder, contains('metabólica'));
    });

    test('Winter formula check: adequate compensation', () {
      // HCO₃=16 → Winter PCO₂ = 1.5×16 + 8 = 32 (±2: 30–34)
      final result = run(
        abg: const AbgInput(ph: 7.30, pco2: 32, hco3: 16, pao2: 90),
      );
      expect(
        result.findings.any((f) => f.text.contains('Winter') &&
            f.text.contains('adequada')),
        isTrue,
      );
    });

    test('Winter formula: inadequate compensation (PCO₂ too high)', () {
      // HCO₃=16 → expected 30–34, actual 42 → inadequate
      final result = run(
        abg: const AbgInput(ph: 7.25, pco2: 42, hco3: 16, pao2: 90),
      );
      expect(
        result.findings.any((f) => f.text.contains('inadequada')),
        isTrue,
      );
    });

    test('lactato > 4 → hiperlactatemia grave', () {
      final result = run(
        abg: const AbgInput(
            ph: 7.28, pco2: 30, hco3: 15, pao2: 90, lactato: 6.0),
      );
      expect(
        result.findings.any((f) =>
            f.level == AlertLevel.danger && f.text.contains('Hiperlactatemia grave')),
        isTrue,
      );
    });

    test('lactato 2–4 → hiperlactatemia warning', () {
      final result = run(
        abg: const AbgInput(
            ph: 7.30, pco2: 30, hco3: 18, pao2: 90, lactato: 3.0),
      );
      expect(
        result.findings.any((f) =>
            f.level == AlertLevel.warning && f.text.contains('Hiperlactatemia')),
        isTrue,
      );
    });

    test('distúrbio misto: acidose respiratória + metabólica', () {
      final result = run(
        abg: const AbgInput(ph: 7.20, pco2: 55, hco3: 18, pao2: 80),
      );
      expect(result.primaryDisorder, contains('misto'));
      expect(result.primaryDisorder, contains('respiratória'));
      expect(result.primaryDisorder, contains('metabólica'));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Alcalose respiratória
  // ═════════════════════════════════════════════════════════════════════════

  group('Alcalose respiratória', () {
    test('pH > 7.45 + PCO₂ < 35 → alcalose respiratória', () {
      final result = run(
        abg: const AbgInput(ph: 7.50, pco2: 28, hco3: 24, pao2: 100),
      );
      expect(result.primaryDisorder, contains('Alcalose respiratória'));
    });

    test('recommends FR reduction', () {
      final result = run(
        abg: const AbgInput(ph: 7.50, pco2: 28, hco3: 24, pao2: 100),
        vent: defaultVent.copyWith(rr: 20),
      );
      expect(
        result.actions.any((a) => a.param == 'FR' && a.action.contains('Reduzir')),
        isTrue,
      );
    });

    test('recommends VT reduction when VT/kg > 8', () {
      final ibw = defaultPatient.ibw;
      final highVt = (ibw * 10).round(); // 10 mL/kg → way above 8
      final result = run(
        abg: const AbgInput(ph: 7.50, pco2: 28, hco3: 24, pao2: 100),
        vent: defaultVent.copyWith(vt: highVt),
      );
      expect(
        result.actions.any((a) => a.param == 'VT' && a.action.contains('Reduzir')),
        isTrue,
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Alcalose metabólica
  // ═════════════════════════════════════════════════════════════════════════

  group('Alcalose metabólica', () {
    test('pH > 7.45 + HCO₃ > 26 → alcalose metabólica', () {
      final result = run(
        abg: const AbgInput(ph: 7.50, pco2: 40, hco3: 32, pao2: 95),
      );
      expect(result.primaryDisorder, contains('metabólica'));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Distúrbio misto compensado (pH normal)
  // ═════════════════════════════════════════════════════════════════════════

  group('Distúrbio misto compensado', () {
    test('pH normal + PCO₂ alto + HCO₃ alto → misto compensado', () {
      final result = run(
        abg: const AbgInput(ph: 7.40, pco2: 50, hco3: 30, pao2: 90),
      );
      expect(result.primaryDisorder, contains('misto compensado'));
    });

    test('pH normal + PCO₂ baixo + HCO₃ baixo → misto compensado', () {
      final result = run(
        abg: const AbgInput(ph: 7.40, pco2: 30, hco3: 18, pao2: 95),
      );
      expect(result.primaryDisorder, contains('misto compensado'));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Oxigenação
  // ═════════════════════════════════════════════════════════════════════════

  group('Oxigenação', () {
    test('PaO₂ < 60 → hipoxemia grave + urgent FiO₂ action', () {
      final result = run(
        abg: normalAbg.copyWith(pao2: 50),
      );
      expect(
        result.findings.any((f) =>
            f.level == AlertLevel.danger && f.text.contains('Hipoxemia grave')),
        isTrue,
      );
      expect(
        result.actions.any(
            (a) => a.param == 'FiO₂' && a.priority == 0),
        isTrue,
      );
    });

    test('PaO₂ < 60 → also recommends PEEP increase', () {
      final result = run(
        abg: normalAbg.copyWith(pao2: 55),
        vent: defaultVent.copyWith(peep: 8),
      );
      expect(
        result.actions.any((a) => a.param == 'PEEP'),
        isTrue,
      );
    });

    test('PaO₂ 60–80 → hipoxemia leve-moderada', () {
      final result = run(
        abg: normalAbg.copyWith(pao2: 70),
      );
      expect(
        result.findings.any((f) =>
            f.level == AlertLevel.warning &&
            f.text.contains('leve-moderada')),
        isTrue,
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // P/F Ratio — Berlin ARDS classification
  // ═════════════════════════════════════════════════════════════════════════

  group('P/F ratio — SDRA Berlin', () {
    test('P/F < 100 → SDRA grave', () {
      // PaO₂=80, FiO₂=100% → P/F=80
      final result = run(
        abg: normalAbg.copyWith(pao2: 80),
        vent: defaultVent.copyWith(fio2: 100),
      );
      expect(result.pfRatio, lessThan(100));
      expect(
        result.findings.any((f) => f.text.contains('SDRA GRAVE')),
        isTrue,
      );
      // Should recommend prona
      expect(
        result.actions.any((a) => a.action.contains('prona')),
        isTrue,
      );
    });

    test('P/F 100–200 → SDRA moderada', () {
      // PaO₂=90, FiO₂=60% → P/F=150
      final result = run(
        abg: normalAbg.copyWith(pao2: 90),
        vent: defaultVent.copyWith(fio2: 60),
      );
      expect(result.pfRatio, greaterThanOrEqualTo(100));
      expect(result.pfRatio, lessThan(200));
      expect(
        result.findings.any((f) => f.text.contains('SDRA MODERADA')),
        isTrue,
      );
    });

    test('P/F 200–300 → SDRA leve', () {
      // PaO₂=95, FiO₂=40% → P/F=237.5
      final result = run();
      expect(result.pfRatio, greaterThanOrEqualTo(200));
      expect(result.pfRatio, lessThan(300));
      expect(
        result.findings.any((f) => f.text.contains('SDRA LEVE')),
        isTrue,
      );
    });

    test('P/F > 300 → no SDRA finding', () {
      // PaO₂=95, FiO₂=21% → P/F≈452
      final result = run(
        vent: defaultVent.copyWith(fio2: 21),
      );
      expect(result.pfRatio, greaterThan(300));
      expect(
        result.findings.any((f) => f.text.contains('SDRA')),
        isFalse,
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // FiO₂ weaning (hiperóxia)
  // ═════════════════════════════════════════════════════════════════════════

  group('Desmame de FiO₂', () {
    test('PaO₂ > 100 + FiO₂ > 40% → recommend FiO₂ reduction', () {
      final result = run(
        abg: normalAbg.copyWith(pao2: 120),
        vent: defaultVent.copyWith(fio2: 60),
      );
      expect(
        result.findings.any((f) => f.text.contains('hiperóxia')),
        isTrue,
      );
      expect(
        result.actions.any(
            (a) => a.param == 'FiO₂' && a.action.contains('Reduzir')),
        isTrue,
      );
    });

    test('PaO₂ > 100 + FiO₂ ≤ 40% → no hiperóxia warning', () {
      final result = run(
        abg: normalAbg.copyWith(pao2: 105),
        vent: defaultVent.copyWith(fio2: 30),
      );
      expect(
        result.findings.any((f) => f.text.contains('hiperóxia')),
        isFalse,
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Proteção pulmonar
  // ═════════════════════════════════════════════════════════════════════════

  group('Proteção pulmonar — VT/kg', () {
    test('VT/kg > 8 → VILI danger', () {
      final ibw = defaultPatient.ibw;
      final highVt = (ibw * 10).round();
      final result = run(vent: defaultVent.copyWith(vt: highVt));
      expect(
        result.findings.any((f) =>
            f.level == AlertLevel.danger && f.text.contains('VILI')),
        isTrue,
      );
    });

    test('VT/kg 6–8 → ok', () {
      final ibw = defaultPatient.ibw;
      final goodVt = (ibw * 7).round();
      final result = run(vent: defaultVent.copyWith(vt: goodVt));
      expect(
        result.findings
            .any((f) => f.level == AlertLevel.ok && f.text.contains('protetora')),
        isTrue,
      );
    });

    test('VT/kg < 6 → info about low VT', () {
      final ibw = defaultPatient.ibw;
      final lowVt = (ibw * 4).round();
      final result = run(vent: defaultVent.copyWith(vt: lowVt));
      expect(
        result.findings.any(
            (f) => f.level == AlertLevel.info && f.text.contains('< 6')),
        isTrue,
      );
    });
  });

  group('Proteção pulmonar — Driving Pressure', () {
    test('DP > 15 → danger + action', () {
      // compliance=20, vt=400 → DP=20
      final result = run(
          vent: defaultVent.copyWith(compliance: 20, vt: 400));
      expect(result.drivingPressure, greaterThan(15));
      expect(
        result.findings.any((f) =>
            f.level == AlertLevel.danger &&
            f.text.contains('Driving Pressure') &&
            f.text.contains('> 15')),
        isTrue,
      );
      expect(
        result.actions.any((a) => a.param == 'DP'),
        isTrue,
      );
    });

    test('DP 12–15 → warning', () {
      // compliance=30, vt=420 → DP=14
      final result = run(
          vent: defaultVent.copyWith(compliance: 30, vt: 420));
      expect(result.drivingPressure, greaterThan(12));
      expect(result.drivingPressure, lessThanOrEqualTo(15));
      expect(
        result.findings.any((f) =>
            f.level == AlertLevel.warning &&
            f.text.contains('12–15')),
        isTrue,
      );
    });

    test('DP ≤ 12 → ok', () {
      final result = run();
      expect(result.drivingPressure, lessThanOrEqualTo(12));
      expect(
        result.findings.any((f) =>
            f.level == AlertLevel.ok &&
            f.text.contains('≤ 12')),
        isTrue,
      );
    });
  });

  group('Proteção pulmonar — Plateau Pressure', () {
    test('Pplat > 30 → danger barotrauma', () {
      // compliance=15, vt=500, peep=10 → DP=33.3, Pplat=43.3
      final result = run(
          vent: defaultVent.copyWith(compliance: 15, vt: 500, peep: 10));
      expect(result.pplat, greaterThan(30));
      expect(
        result.findings.any((f) =>
            f.level == AlertLevel.danger && f.text.contains('BAROTRAUMA')),
        isTrue,
      );
      expect(
        result.actions.any((a) => a.param == 'Pplat' && a.priority == 0),
        isTrue,
      );
    });

    test('Pplat 28–30 → warning', () {
      // compliance=30, vt=700, peep=5 → DP=23.3, Pplat=28.3
      final result = run(
          vent: defaultVent.copyWith(compliance: 30, vt: 700, peep: 5));
      expect(result.pplat, greaterThan(28));
      expect(result.pplat, lessThanOrEqualTo(30));
      expect(
        result.findings.any((f) =>
            f.level == AlertLevel.warning && f.text.contains('28–30')),
        isTrue,
      );
    });

    test('Pplat ≤ 28 → ok', () {
      final result = run();
      expect(result.pplat, lessThanOrEqualTo(28));
      expect(
        result.findings.any((f) =>
            f.level == AlertLevel.ok && f.text.contains('≤ 28')),
        isTrue,
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Action sorting
  // ═════════════════════════════════════════════════════════════════════════

  group('Action and finding sorting', () {
    test('actions sorted by priority ascending', () {
      // Severe scenario: multiple actions at different priorities
      final result = run(
        abg: const AbgInput(ph: 7.15, pco2: 70, hco3: 18, pao2: 50, lactato: 5),
        vent: defaultVent.copyWith(fio2: 60, compliance: 15, vt: 500, peep: 10),
      );
      for (int i = 1; i < result.actions.length; i++) {
        expect(result.actions[i].priority,
            greaterThanOrEqualTo(result.actions[i - 1].priority));
      }
    });

    test('findings sorted by severity (danger first)', () {
      final result = run(
        abg: const AbgInput(ph: 7.15, pco2: 70, hco3: 18, pao2: 50, lactato: 5),
        vent: defaultVent.copyWith(fio2: 60, compliance: 15, vt: 500, peep: 10),
      );
      // First finding should be danger
      expect(result.findings.first.level, AlertLevel.danger);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Clinical scenario: ARDS moderate
  // ═════════════════════════════════════════════════════════════════════════

  group('Clinical scenario: SDRA moderada', () {
    test('full ARDS scenario produces expected findings and actions', () {
      final result = run(
        abg: const AbgInput(
          ph: 7.32,
          pco2: 48,
          hco3: 22,
          pao2: 70,
          sao2: 93,
          lactato: 1.5,
        ),
        vent: const VentParams(
          vt: 350,
          rr: 22,
          peep: 12,
          fio2: 60,
          compliance: 25,
          resistance: 8,
        ),
        patient: const PatientData(sex: Sex.male, heightCm: 170),
      );

      // P/F = 70/0.60 ≈ 117 → SDRA moderada
      expect(result.pfRatio, closeTo(116.7, 1));

      // Should identify acidose respiratória
      expect(result.primaryDisorder, contains('respiratória'));

      // Should have SDRA moderada finding
      expect(
        result.findings.any((f) => f.text.contains('SDRA MODERADA')),
        isTrue,
      );

      // Driving pressure = 350/25 = 14 → warning (12–15)
      expect(result.drivingPressure, closeTo(14, 0.1));
    });
  });
}
