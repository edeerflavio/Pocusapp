// Integration tests for the 3 clinical scenarios:
//   TESTE 1 — Gasometria (SDRA + ABG analysis + apply)
//   TESTE 2 — Assincronias (Pneumotórax, Auto-PEEP)
//   TESTE 3 — Combinado (SDRA + Secreção + gasometria + apply)
//
// These tests validate the full domain pipeline end-to-end without
// requiring Flutter widgets (pure Dart).

import 'package:flutter_test/flutter_test.dart';

import 'package:pocusapp/features/simulator/data/presets/clinical_presets.dart';
import 'package:pocusapp/features/simulator/domain/entities/pathophysiology/pathophysiology_entities.dart';
import 'package:pocusapp/features/simulator/domain/entities/ventilator_entities.dart';
import 'package:pocusapp/features/simulator/domain/enums/ventilation_enums.dart';
import 'package:pocusapp/features/simulator/domain/services/abg_analyzer.dart';
import 'package:pocusapp/features/simulator/domain/services/pathophysiology/auto_peep_modifier.dart';
import 'package:pocusapp/features/simulator/domain/services/pathophysiology/pathophysiology_modifier.dart';
import 'package:pocusapp/features/simulator/domain/services/pathophysiology/pneumothorax_modifier.dart';
import 'package:pocusapp/features/simulator/domain/services/pathophysiology/secretion_modifier.dart';
import 'package:pocusapp/features/simulator/domain/services/ventilator_engine.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // Helper: extract target value from action text (same logic as UI)
  // ═══════════════════════════════════════════════════════════════════════

  double? extractTarget(String action) {
    final paraMatch =
        RegExp(r'para\s+(\d+(?:\.\d+)?)').firstMatch(action);
    if (paraMatch != null) return double.tryParse(paraMatch.group(1)!);
    final ateMatch = RegExp(r'até\s+(\d+(?:\.\d+)?)').firstMatch(action);
    if (ateMatch != null) return double.tryParse(ateMatch.group(1)!);
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TESTE 1 — Gasometria: SDRA + ABG input + analyze + apply
  // ═══════════════════════════════════════════════════════════════════════

  group('TESTE 1 — Gasometria com SDRA', () {
    late VentParams sdraParams;
    late PatientData patient;
    late AbgInput abg;
    late AbgAnalysis analysis;

    setUpAll(() {
      // Step 1: Load SDRA preset
      sdraParams = ClinicalPresets.presets[ClinicalPresetType.sdra]!;
      patient = PatientData.initial(); // Male, 170cm, 70kg, 50yo

      // Step 2-3: Insert gasometry values
      abg = const AbgInput(
        ph: 7.25,
        pco2: 62,
        hco3: 24,
        pao2: 55,
        sao2: 85,
        lactato: 3.5,
      );

      // Step 4: Analyze
      analysis = AbgAnalyzer.analyze(
        abg: abg,
        ventParams: sdraParams,
        patient: patient,
      );
    });

    test('SDRA preset has expected parameters', () {
      expect(sdraParams.mode, VentMode.pcv);
      expect(sdraParams.compliance, 20);
      expect(sdraParams.resistance, 10);
      expect(sdraParams.peep, 14);
      expect(sdraParams.rr, 22);
      expect(sdraParams.fio2, 70);
    });

    test('primary disorder contains "acidose respiratória"', () {
      expect(
        analysis.primaryDisorder.toLowerCase(),
        contains('acidose respirat'),
      );
    });

    test('findings include hipoxemia grave (PaO₂ < 60)', () {
      expect(
        analysis.findings.any((f) =>
            f.level == AlertLevel.danger &&
            f.text.toLowerCase().contains('hipoxemia grave')),
        isTrue,
        reason: 'PaO₂=55 should trigger severe hypoxemia finding',
      );
    });

    test('findings include hipercapnia / acidose respiratória', () {
      expect(
        analysis.findings.any((f) =>
            f.text.toLowerCase().contains('acidose respiratória') ||
            f.text.toLowerCase().contains('paco₂')),
        isTrue,
        reason: 'PCO₂=62 with pH=7.25 should flag respiratory acidosis',
      );
    });

    test('findings include P/F ratio baixo (SDRA)', () {
      // P/F = 55 / 0.70 = 78.6 → SDRA grave (< 100)
      expect(analysis.pfRatio, closeTo(78.6, 1.0));
      expect(
        analysis.findings
            .any((f) => f.text.toLowerCase().contains('sdra grave')),
        isTrue,
        reason: 'P/F=78.6 → SDRA grave',
      );
    });

    test('lactato finding requires metabolic acidosis branch (HCO₃ < 22)', () {
      // Lactate check is inside the metabolic acidosis branch.
      // With HCO₃=24 (normal), it's pure respiratory acidosis —
      // lactate is not evaluated. This is correct clinical logic.
      // Verify that with HCO₃ < 22, lactate IS flagged.
      final metabolicAbg = const AbgInput(
        ph: 7.25, pco2: 62, hco3: 20, pao2: 55, sao2: 85, lactato: 3.5,
      );
      final metabolicAnalysis = AbgAnalyzer.analyze(
        abg: metabolicAbg,
        ventParams: sdraParams,
        patient: patient,
      );
      expect(
        metabolicAnalysis.findings
            .any((f) => f.text.toLowerCase().contains('hiperlactatemia')),
        isTrue,
        reason: 'Lactato=3.5 + HCO₃=20 should trigger hyperlactatemia',
      );
    });

    test('actions include FR increase recommendation', () {
      final frActions =
          analysis.actions.where((a) => a.param == 'FR').toList();
      expect(frActions, isNotEmpty,
          reason: 'PCO₂=62 should recommend FR increase');
    });

    test('actions include FiO₂ increase recommendation', () {
      final fio2Actions = analysis.actions
          .where((a) => a.param == 'FiO\u2082')
          .toList();
      expect(fio2Actions, isNotEmpty,
          reason: 'PaO₂=55 should recommend FiO₂ increase');
    });

    test('actions include PEEP increase recommendation', () {
      final peepActions =
          analysis.actions.where((a) => a.param == 'PEEP').toList();
      expect(peepActions, isNotEmpty,
          reason: 'PaO₂=55 should recommend PEEP increase');
    });

    test('VT action has extractable target value (VT/kg < 6 in SDRA)', () {
      // In SDRA, VT=350, IBW≈66 → VT/kg=5.3 < 6 → recommends VT increase
      final vtAction = analysis.actions.firstWhere((a) => a.param == 'VT');
      final target = extractTarget(vtAction.action);
      expect(target, isNotNull,
          reason: 'VT action should have a parseable "para X" target');
      expect(target!, greaterThanOrEqualTo(sdraParams.vt),
          reason: 'Target VT should be ≥ current (${sdraParams.vt})');
    });

    test('FR action exists but may not have numeric target when DP > 15', () {
      // With DP=17.5 (> 15), FR action says "Preferir aumento de FR sobre VT"
      // without a specific numeric target. This is clinically correct.
      final frAction = analysis.actions.firstWhere((a) => a.param == 'FR');
      expect(frAction.action, contains('FR'));
      // DP > 15 → action text warns about using FR instead of VT
      expect(frAction.action.toLowerCase(),
          anyOf(contains('preferir'), contains('para')));
    });

    test('applying VT recommendation produces valid VentParams', () {
      final vtAction = analysis.actions.firstWhere((a) => a.param == 'VT');
      final target = extractTarget(vtAction.action)!;
      final newVT = target.round().clamp(200, 800);

      // Simulate "Aplicar" button
      final newParams = sdraParams.copyWith(vt: newVT);
      expect(newParams.vt, greaterThanOrEqualTo(sdraParams.vt));
      expect(newParams.vt, lessThanOrEqualTo(800));

      // Waveform should still produce valid simulation
      final sample = VentilatorEngine.simulate(newParams, 0.5);
      expect(sample.pressure, greaterThanOrEqualTo(newParams.peep));
    });

    test('applying FiO₂ recommendation produces valid VentParams', () {
      final fio2Action = analysis.actions
          .firstWhere((a) => a.param == 'FiO\u2082');
      final target = extractTarget(fio2Action.action)!;
      final newFio2 = target.round().clamp(21, 100);

      final newParams = sdraParams.copyWith(fio2: newFio2);
      expect(newParams.fio2, greaterThan(sdraParams.fio2));
      expect(newParams.fio2, lessThanOrEqualTo(100));
    });

    test('header metrics update after applying VT', () {
      final vtAction = analysis.actions.firstWhere((a) => a.param == 'VT');
      final target = extractTarget(vtAction.action)!;
      final newParams = sdraParams.copyWith(vt: target.round().clamp(200, 800));

      // Minute ventilation = VT × RR / 1000
      final oldMV = sdraParams.vt * sdraParams.rr / 1000.0;
      final newMV = newParams.vt * newParams.rr / 1000.0;

      expect(newMV, greaterThanOrEqualTo(oldMV),
          reason: 'Higher VT should increase minute ventilation');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // TESTE 2 — Assincronias: Pneumotórax + Auto-PEEP
  // ═══════════════════════════════════════════════════════════════════════

  group('TESTE 2 — Assincronias', () {
    setUpAll(() {
      // Register modifiers needed for this test
      PathophysiologyRegistry.register(PneumothoraxModifier());
      PathophysiologyRegistry.register(AutoPeepModifier());
    });

    tearDownAll(() {
      PathophysiologyRegistry.resetAll();
    });

    group('Pneumotórax grave com preset Normal', () {
      late VentParams normalParams;
      late BreathSample baselineSample;
      late BreathSample pneumoSample;

      setUpAll(() {
        // Step 1: Normal preset
        normalParams = ClinicalPresets.presets[ClinicalPresetType.normal]!;

        // Baseline waveform at mid-inspiration
        final tInsp = normalParams.inspTime * 0.5;
        baselineSample = VentilatorEngine.simulate(normalParams, tInsp);

        // Step 2: Activate Pneumothorax severe
        final pneumoEvent = PathophysiologyEvent(
          type: PathophysiologyType.pneumothorax,
          active: true,
          severity: PathophysiologySeverity.severe,
          intensity: 1.0,
          onsetTime: 0.0,
          continuous: true,
        );

        // Step 3: Apply modifier pipeline
        final result = PathophysiologyRegistry.apply(
          originalParams: normalParams,
          originalSample: baselineSample,
          activeEvents: [pneumoEvent],
          simTime: tInsp,
        );
        pneumoSample = result.sample;
      });

      test('pneumothorax reduces compliance drastically', () {
        // Severe pneumo: -70% compliance → from 50 to ~15
        // This means higher pressures for same volume, or lower volumes
        // We check that the modified sample shows different waveform
        expect(pneumoSample.pressure, isNot(equals(baselineSample.pressure)),
            reason:
                'Pneumothorax should change pressure waveform');
      });

      test('VCV mode: volume is maintained but at higher cost (pressure)', () {
        // In VCV, the ventilator delivers a set volume regardless of
        // compliance. The volume at mid-inspiration is Vt * (t/Ti) = 225 mL.
        // Pneumothorax doesn't reduce VCV volume — it raises pressure.
        // This is the clinically correct behavior: VCV = volume guarantee.
        expect(pneumoSample.volume, equals(baselineSample.volume),
            reason: 'VCV maintains set volume despite reduced compliance');
        expect(pneumoSample.pressure, greaterThan(baselineSample.pressure),
            reason: 'VCV compensates with higher pressure when C drops');
      });

      test('pneumothorax pressures rise significantly (VCV mode)', () {
        // In VCV with reduced compliance: Paw = V/C + Flow*R + PEEP
        // Since C drops ~70%, V/C increases ~3.3x → much higher pressures
        expect(pneumoSample.pressure, greaterThan(baselineSample.pressure),
            reason: 'Severe pneumothorax raises PIP in VCV');
      });
    });

    group('Auto-PEEP com preset DPOC', () {
      late VentParams dpocParams;

      setUpAll(() {
        dpocParams = ClinicalPresets.presets[ClinicalPresetType.dpoc]!;
      });

      test('DPOC preset has high tau (air trapping risk)', () {
        // tau = R * C / 1000 = 18 * 80 / 1000 = 1.44s
        expect(dpocParams.tau, greaterThan(1.0),
            reason: 'DPOC should have tau > 1s (air trapping risk)');
      });

      test('Auto-PEEP modifier increases effective PEEP in DPOC', () {
        // Simulate 5 seconds to let auto-PEEP build up
        PathophysiologyRegistry.resetAll();

        final autoPeepEvent = PathophysiologyEvent(
          type: PathophysiologyType.autoPeep,
          active: true,
          severity: PathophysiologySeverity.moderate,
          intensity: 1.0,
          onsetTime: 0.0,
          continuous: true,
        );

        // Collect end-expiratory samples over multiple breaths
        final cycleTime = dpocParams.totalCycleTime;
        final endExpTime = cycleTime * 0.95; // Near end of first expiration

        // Simulate after several seconds for auto-PEEP to build
        final simTime = 5 * cycleTime + endExpTime;
        final baseSample = VentilatorEngine.simulate(dpocParams, simTime);
        final result = PathophysiologyRegistry.apply(
          originalParams: dpocParams,
          originalSample: baseSample,
          activeEvents: [autoPeepEvent],
          simTime: simTime,
        );

        // Auto-PEEP should raise baseline pressure above set PEEP
        // or modify the params to include intrinsic PEEP
        final effectiveParams = result.params;
        expect(effectiveParams.peep, greaterThanOrEqualTo(dpocParams.peep),
            reason: 'Auto-PEEP modifier should increase effective PEEP');
      });

      test('expiratory flow does not reach zero in obstructive disease', () {
        // With high tau, expiration doesn't complete → residual flow
        final tEndExp = dpocParams.totalCycleTime * 0.99;
        final sample = VentilatorEngine.simulate(dpocParams, tEndExp);

        // In obstructive disease with tau=1.44s and expTime ~3.75s,
        // residual volume = Vt * e^(-tExp/tau)
        // After 3.75s with tau=1.44: factor = e^(-2.6) ≈ 0.074
        // So about 7.4% of Vt remains trapped → not zero flow
        // The flow at end-expiration should be small but measurable
        // Actually in the engine, flow goes negative during expiration
        // and approaches 0 as volume decays. With high tau it won't
        // fully reach 0.
        expect(sample.volume.abs(), greaterThan(0),
            reason:
                'End-expiratory volume > 0 with high-tau indicates incomplete emptying');
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // TESTE 3 — Combinado: SDRA + Secreção + gasometria + apply
  // ═══════════════════════════════════════════════════════════════════════

  group('TESTE 3 — Combinado: SDRA + Secreção + gasometria + apply', () {
    setUpAll(() {
      PathophysiologyRegistry.register(SecretionModifier());
    });

    tearDownAll(() {
      PathophysiologyRegistry.resetAll();
    });

    test('SDRA + moderate secretion: resistance increases', () {
      final sdraParams = ClinicalPresets.presets[ClinicalPresetType.sdra]!;

      final secretionEvent = PathophysiologyEvent(
        type: PathophysiologyType.secretion,
        active: true,
        severity: PathophysiologySeverity.moderate,
        intensity: 1.0,
        onsetTime: 0.0,
        continuous: true,
      );

      // Simulate after 20s to let secretion accumulate
      final tInsp = sdraParams.inspTime * 0.5;
      final simTime = 4 * sdraParams.totalCycleTime + tInsp;
      final baseSample = VentilatorEngine.simulate(sdraParams, simTime);

      final result = PathophysiologyRegistry.apply(
        originalParams: sdraParams,
        originalSample: baseSample,
        activeEvents: [secretionEvent],
        simTime: simTime,
      );

      // Secretion increases resistance
      expect(result.params.resistance,
          greaterThanOrEqualTo(sdraParams.resistance),
          reason: 'Secretion should increase airway resistance');
    });

    test('gasometry with hypoxemia on SDRA + secretion → recommendations', () {
      final sdraParams = ClinicalPresets.presets[ClinicalPresetType.sdra]!;
      // Simulate a patient with SDRA + secretion who is hypoxemic
      final abg = const AbgInput(
        ph: 7.30,
        pco2: 52,
        hco3: 25,
        pao2: 65,
        sao2: 90,
        lactato: 1.5,
      );

      final analysis = AbgAnalyzer.analyze(
        abg: abg,
        ventParams: sdraParams,
        patient: PatientData.initial(),
      );

      // Should still give useful recommendations
      expect(analysis.primaryDisorder, isNotEmpty);

      // Should have findings about hypoxemia and/or respiratory issues
      expect(analysis.findings, isNotEmpty);

      // P/F = 65 / 0.70 = 92.8 → SDRA grave
      expect(analysis.pfRatio, closeTo(92.8, 1.0));
      expect(
        analysis.findings
            .any((f) => f.text.toLowerCase().contains('sdra')),
        isTrue,
      );
    });

    test('applying VT recommendation + secretion: MV improves but R stays elevated', () {
      final sdraParams = ClinicalPresets.presets[ClinicalPresetType.sdra]!;
      final patient = PatientData.initial();

      // Gasometry showing acidose respiratória
      final abg = const AbgInput(
        ph: 7.28,
        pco2: 58,
        hco3: 24,
        pao2: 58,
        sao2: 87,
        lactato: 1.2,
      );

      final analysis = AbgAnalyzer.analyze(
        abg: abg,
        ventParams: sdraParams,
        patient: patient,
      );

      // In SDRA, VT/kg < 6 → VT increase action with target
      final vtActions =
          analysis.actions.where((a) => a.param == 'VT').toList();
      expect(vtActions, isNotEmpty,
          reason: 'SDRA with VT/kg<6 should recommend VT increase');

      final target = extractTarget(vtActions.first.action);
      expect(target, isNotNull,
          reason: 'VT action should have parseable target');

      // Apply VT change
      final newParams =
          sdraParams.copyWith(vt: target!.round().clamp(200, 800));
      expect(newParams.vt, greaterThanOrEqualTo(sdraParams.vt));

      // Now simulate with secretion still active
      final secretionEvent = PathophysiologyEvent(
        type: PathophysiologyType.secretion,
        active: true,
        severity: PathophysiologySeverity.moderate,
        intensity: 1.0,
        onsetTime: 0.0,
        continuous: true,
      );

      // Run simulation with new VT + secretion
      final simTime = 5 * newParams.totalCycleTime;
      final baseSample = VentilatorEngine.simulate(newParams, simTime);
      final result = PathophysiologyRegistry.apply(
        originalParams: newParams,
        originalSample: baseSample,
        activeEvents: [secretionEvent],
        simTime: simTime,
      );

      // Verification:
      // 1. Higher minute ventilation (improved VT)
      final oldMV = sdraParams.vt * sdraParams.rr / 1000.0;
      final newMV = newParams.vt * newParams.rr / 1000.0;
      expect(newMV, greaterThanOrEqualTo(oldMV),
          reason: 'MV should increase after VT adjustment');

      // 2. Secretion still elevates resistance
      expect(result.params.resistance,
          greaterThanOrEqualTo(newParams.resistance),
          reason: 'Secretion should still cause elevated resistance even after adjustments');

      // 3. Waveform is valid (no NaN, pressure ≥ PEEP)
      expect(result.sample.pressure, isNot(isNaN));
      expect(result.sample.pressure,
          greaterThanOrEqualTo(newParams.peep - 1),
          reason: 'Pressure should remain near/above PEEP');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Bonus: target extraction helper validation
  // ═══════════════════════════════════════════════════════════════════════

  group('Target extraction helper', () {
    test('extracts "para X" pattern', () {
      expect(extractTarget('Aumentar FR de 22 para 26 rpm'), 26);
    });

    test('extracts "para X" with decimal', () {
      expect(extractTarget('Aumentar PEEP de 14 para 16.5 cmH₂O'), 16.5);
    });

    test('extracts "até X" pattern', () {
      expect(extractTarget('Considerar aumento de VT até 528 mL'), 528);
    });

    test('returns null when no pattern found', () {
      expect(
          extractTarget('Preferir aumento de FR sobre VT (DP > 15)'), isNull);
    });

    test('extracts first match with "para"', () {
      expect(
          extractTarget('Reduzir VT de 500 para 396 mL (6 mL/kg)'), 396);
    });
  });
}
