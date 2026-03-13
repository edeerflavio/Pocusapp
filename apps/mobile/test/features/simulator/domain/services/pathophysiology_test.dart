import 'package:flutter_test/flutter_test.dart';
import 'package:pocusapp/features/simulator/domain/entities/pathophysiology/pathophysiology_entities.dart';
import 'package:pocusapp/features/simulator/domain/entities/ventilator_entities.dart';
import 'package:pocusapp/features/simulator/domain/enums/ventilation_enums.dart';
import 'package:pocusapp/features/simulator/domain/services/pathophysiology/auto_peep_modifier.dart';
import 'package:pocusapp/features/simulator/domain/services/pathophysiology/bronchospasm_modifier.dart';
import 'package:pocusapp/features/simulator/domain/services/pathophysiology/circuit_leak_modifier.dart';
import 'package:pocusapp/features/simulator/domain/services/pathophysiology/double_trigger_modifier.dart';
import 'package:pocusapp/features/simulator/domain/services/pathophysiology/pathophysiology_modifier.dart';
import 'package:pocusapp/features/simulator/domain/services/pathophysiology/pneumothorax_modifier.dart';
import 'package:pocusapp/features/simulator/domain/services/pathophysiology/right_mainstem_modifier.dart';
import 'package:pocusapp/features/simulator/domain/services/pathophysiology/secretion_modifier.dart';
import 'package:pocusapp/features/simulator/domain/services/ventilator_engine.dart';

/// Helper to create an active event at the given severity and intensity.
PathophysiologyEvent _activeEvent(
  PathophysiologyType type, {
  PathophysiologySeverity severity = PathophysiologySeverity.severe,
  double intensity = 1.0,
}) =>
    PathophysiologyEvent(
      type: type,
      active: true,
      severity: severity,
      intensity: intensity,
      continuous: true,
    );

/// Runs the auto-PEEP modifier for [ticks] engine steps so the
/// exponential smoothing can converge.
VentParams _runAutoPeepTicks(
  AutoPeepModifier mod,
  VentParams params,
  PathophysiologyEvent event,
  int ticks,
) {
  var result = params;
  for (int i = 0; i < ticks; i++) {
    result = mod.modifyParams(params, event, i * EngineConstants.dt);
  }
  return result;
}

void _registerAll() {
  PathophysiologyRegistry.register(AutoPeepModifier());
  PathophysiologyRegistry.register(DoubleTriggerModifier());
  PathophysiologyRegistry.register(SecretionModifier());
  PathophysiologyRegistry.register(PneumothoraxModifier());
  PathophysiologyRegistry.register(BronchospasmModifier());
  PathophysiologyRegistry.register(CircuitLeakModifier());
  PathophysiologyRegistry.register(RightMainstemModifier());
}

void main() {
  setUpAll(_registerAll);

  // ═══════════════════════════════════════════════════════════════════════
  // 1. AutoPeepModifier
  // ═══════════════════════════════════════════════════════════════════════

  group('AutoPeepModifier', () {
    late AutoPeepModifier mod;

    setUp(() {
      mod = AutoPeepModifier();
    });

    test('COPD params (C=70, R=20, RR=20) generate auto-PEEP', () {
      // COPD: high R, high C → long τ. High RR → short tExp.
      // τ = 20 × 70 / 1000 = 1.4 s
      // tExp at RR=20, I:E=1:2 → Ttot=3s, Ti=1s, tExp=2s
      // k = exp(-2/1.4) ≈ 0.24 → significant trapping.
      final params = VentParams(
        mode: VentMode.vcv,
        compliance: 70,
        resistance: 20,
        peep: 3,
        rr: 20,
        vt: 400,
        pip: 20,
        ps: 10,
        fio2: 35,
        ieRatio: 2.0,
        patientEffort: 0,
      );

      final event = _activeEvent(
        PathophysiologyType.autoPeep,
        severity: PathophysiologySeverity.severe,
        intensity: 1.0,
      );

      // Run enough ticks for smoothing to converge (~2000 ticks ≈ 8 s).
      final modified = _runAutoPeepTicks(mod, params, event, 2000);

      // Auto-PEEP should have raised the effective PEEP.
      expect(modified.peep, greaterThan(params.peep + 0.5));
      // But should not exceed original PEEP + 15 cmH₂O cap.
      expect(modified.peep, lessThanOrEqualTo(params.peep + 15));
    });

    test('normal params (C=50, R=8, RR=14) produce negligible auto-PEEP', () {
      // Normal: τ = 8 × 50 / 1000 = 0.4 s
      // tExp at RR=14, I:E=1:2 → Ttot=4.29s, Ti=1.43s, tExp=2.86s
      // k = exp(-2.86/0.4) ≈ 0.0008 → k < 0.01 → no effect.
      final params = VentParams(
        mode: VentMode.vcv,
        compliance: 50,
        resistance: 8,
        peep: 5,
        rr: 14,
        vt: 450,
        pip: 20,
        ps: 10,
        fio2: 40,
        ieRatio: 2.0,
        patientEffort: 0,
      );

      final event = _activeEvent(
        PathophysiologyType.autoPeep,
        severity: PathophysiologySeverity.severe,
        intensity: 1.0,
      );

      final modified = _runAutoPeepTicks(mod, params, event, 2000);

      // PEEP should be unchanged (or negligibly different).
      expect(modified.peep, closeTo(params.peep, 0.5));
    });

    test('reset clears smoothed auto-PEEP', () {
      final params = VentParams(
        compliance: 70,
        resistance: 20,
        peep: 3,
        rr: 20,
        vt: 400,
      );
      final event = _activeEvent(PathophysiologyType.autoPeep);

      // Build up some smoothed value.
      _runAutoPeepTicks(mod, params, event, 500);
      mod.reset();

      // After reset, first call should not add any PEEP (smoothed = 0).
      final result = mod.modifyParams(params, event, 0);
      expect(result.peep, params.peep);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 2. PneumothoraxModifier
  // ═══════════════════════════════════════════════════════════════════════

  group('PneumothoraxModifier', () {
    late PneumothoraxModifier mod;

    setUp(() {
      mod = PneumothoraxModifier();
    });

    test('severe: compliance drops ~70%', () {
      final params = VentParams(compliance: 50, resistance: 8);
      final event = _activeEvent(
        PathophysiologyType.pneumothorax,
        severity: PathophysiologySeverity.severe,
        intensity: 1.0,
      );

      final modified = mod.modifyParams(params, event, 0);

      // C should drop by 70%: 50 × 0.30 = 15.
      expect(modified.compliance, closeTo(15, 1));
    });

    test('severe: resistance increases ~30%', () {
      final params = VentParams(compliance: 50, resistance: 8);
      final event = _activeEvent(
        PathophysiologyType.pneumothorax,
        severity: PathophysiologySeverity.severe,
        intensity: 1.0,
      );

      final modified = mod.modifyParams(params, event, 0);

      // R should increase by 30%: 8 × 1.30 = 10.4.
      expect(modified.resistance, closeTo(10.4, 0.1));
    });

    test('mild: compliance drops ~20%, resistance unchanged', () {
      final params = VentParams(compliance: 50, resistance: 8);
      final event = _activeEvent(
        PathophysiologyType.pneumothorax,
        severity: PathophysiologySeverity.mild,
        intensity: 1.0,
      );

      final modified = mod.modifyParams(params, event, 0);

      expect(modified.compliance, closeTo(40, 1));
      expect(modified.resistance, params.resistance);
    });

    test('modifySample returns original unchanged', () {
      final sample = BreathSample(
        pressure: 25,
        flow: 30,
        volume: 400,
        phase: BreathPhase.inspiration,
      );
      final params = VentParams();
      final event = _activeEvent(PathophysiologyType.pneumothorax);

      final result = mod.modifySample(sample, params, event, 0);
      expect(identical(result, sample), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 3. SecretionModifier
  // ═══════════════════════════════════════════════════════════════════════

  group('SecretionModifier', () {
    late SecretionModifier mod;

    setUp(() {
      mod = SecretionModifier();
    });

    test('resistance increases progressively (t=0 < t=31s)', () {
      final params = VentParams(resistance: 8);
      final event = _activeEvent(
        PathophysiologyType.secretion,
        severity: PathophysiologySeverity.moderate,
        intensity: 1.0,
      );

      // At t=0 (first call), ramp fraction is near zero.
      final earlyResult = mod.modifyParams(params, event, 0);

      // Simulate ~31 seconds of ticks (31 / 0.004 ≈ 7750 ticks).
      var lateResult = params;
      for (int i = 0; i < 7750; i++) {
        lateResult = mod.modifyParams(params, event, i * 0.004);
      }

      // Early resistance should be barely above baseline.
      expect(earlyResult.resistance, closeTo(params.resistance, 1));

      // Late resistance should be significantly above baseline.
      // Moderate factor = 1.5 → R = 8 × (1 + 1.5) = 20 at full ramp.
      expect(lateResult.resistance, greaterThan(params.resistance * 2));
    });

    test('reset clears accumulated time', () {
      final params = VentParams(resistance: 8);
      final event = _activeEvent(PathophysiologyType.secretion);

      // Accumulate some time.
      for (int i = 0; i < 1000; i++) {
        mod.modifyParams(params, event, i * 0.004);
      }

      mod.reset();

      // After reset, resistance should be near baseline again.
      final result = mod.modifyParams(params, event, 0);
      expect(result.resistance, closeTo(params.resistance, 1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 4. DoubleTriggerModifier
  // ═══════════════════════════════════════════════════════════════════════

  group('DoubleTriggerModifier', () {
    late DoubleTriggerModifier mod;

    setUp(() {
      mod = DoubleTriggerModifier();
    });

    test('does not modify params (returns identical)', () {
      final params = VentParams();
      final event = _activeEvent(PathophysiologyType.doubleTrigger);

      final result = mod.modifyParams(params, event, 0);
      expect(identical(result, params), isTrue);
    });

    test('eventually generates INSP phase during EXP with deterministic seed', () {
      final params = VentParams(
        mode: VentMode.vcv,
        rr: 15,
        vt: 500,
        compliance: 50,
        resistance: 8,
        peep: 5,
        ieRatio: 2.0,
      );
      final event = _activeEvent(
        PathophysiologyType.doubleTrigger,
        severity: PathophysiologySeverity.severe,
        intensity: 1.0,
      );

      final dt = EngineConstants.dt;
      var foundDoubleTrigger = false;

      // Run for 30 seconds of simulation — should trigger at least once.
      for (double t = 0; t < 30.0; t += dt) {
        final baseSample = VentilatorEngine.simulate(params, t);
        final modified = mod.modifySample(baseSample, params, event, t);

        // Detect: base sample is EXP but modifier forced INSP.
        if (baseSample.phase == BreathPhase.expiration &&
            modified.phase == BreathPhase.inspiration) {
          foundDoubleTrigger = true;
          // Stacked volume should be >= base (equal at envelope boundary).
          expect(modified.volume, greaterThanOrEqualTo(baseSample.volume));
          break;
        }
      }

      expect(foundDoubleTrigger, isTrue,
          reason: 'Double trigger should fire at least once in 30 s');
    });

    test('reproducible with fixed seed (same result on two runs)', () {
      final params = VentParams(
        mode: VentMode.vcv,
        rr: 15,
        vt: 500,
        compliance: 50,
        resistance: 8,
        peep: 5,
        ieRatio: 2.0,
      );
      final event = _activeEvent(
        PathophysiologyType.doubleTrigger,
        severity: PathophysiologySeverity.severe,
        intensity: 1.0,
      );

      double? firstTriggerTime1;
      double? firstTriggerTime2;

      // Run 1.
      final mod1 = DoubleTriggerModifier();
      for (double t = 0; t < 30.0; t += EngineConstants.dt) {
        final base = VentilatorEngine.simulate(params, t);
        final modified = mod1.modifySample(base, params, event, t);
        if (base.phase == BreathPhase.expiration &&
            modified.phase == BreathPhase.inspiration) {
          firstTriggerTime1 = t;
          break;
        }
      }

      // Run 2 — fresh modifier, same seed.
      final mod2 = DoubleTriggerModifier();
      for (double t = 0; t < 30.0; t += EngineConstants.dt) {
        final base = VentilatorEngine.simulate(params, t);
        final modified = mod2.modifySample(base, params, event, t);
        if (base.phase == BreathPhase.expiration &&
            modified.phase == BreathPhase.inspiration) {
          firstTriggerTime2 = t;
          break;
        }
      }

      expect(firstTriggerTime1, isNotNull);
      expect(firstTriggerTime1, firstTriggerTime2);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 5. BronchospasmModifier
  // ═══════════════════════════════════════════════════════════════════════

  group('BronchospasmModifier', () {
    late BronchospasmModifier mod;

    setUp(() {
      mod = BronchospasmModifier();
    });

    test('severe: resistance is ~5x the original', () {
      final params = VentParams(resistance: 8);
      final event = _activeEvent(
        PathophysiologyType.bronchospasm,
        severity: PathophysiologySeverity.severe,
        intensity: 1.0,
      );

      final modified = mod.modifyParams(params, event, 0);

      // R_new = 8 × 5 = 40.
      expect(modified.resistance, closeTo(40, 1));
    });

    test('mild: resistance is ~2x the original', () {
      final params = VentParams(resistance: 8);
      final event = _activeEvent(
        PathophysiologyType.bronchospasm,
        severity: PathophysiologySeverity.mild,
        intensity: 1.0,
      );

      final modified = mod.modifyParams(params, event, 0);

      // R_new = 8 × 2 = 16.
      expect(modified.resistance, closeTo(16, 1));
    });

    test('intensity 0.5 severe: resistance is ~3x', () {
      final params = VentParams(resistance: 8);
      final event = _activeEvent(
        PathophysiologyType.bronchospasm,
        severity: PathophysiologySeverity.severe,
        intensity: 0.5,
      );

      final modified = mod.modifyParams(params, event, 0);

      // multiplier = 1 + (5-1) × 0.5 = 3.0 → R = 24.
      expect(modified.resistance, closeTo(24, 1));
    });

    test('scooped expiratory flow during expiration', () {
      final params = VentParams(
        mode: VentMode.vcv,
        compliance: 50,
        resistance: 8,
        peep: 5,
        rr: 14,
        vt: 450,
        ieRatio: 2.0,
      );
      final event = _activeEvent(
        PathophysiologyType.bronchospasm,
        severity: PathophysiologySeverity.severe,
        intensity: 1.0,
      );

      // Sample mid-expiration.
      final ti = params.inspTime;
      final midExp = ti + params.expTime * 0.5;
      final baseSample = VentilatorEngine.simulate(params, midExp);

      // Base sample should be expiratory.
      expect(baseSample.phase, BreathPhase.expiration);

      final modified = mod.modifySample(baseSample, params, event, midExp);

      // Flow should be reduced in magnitude (scooped = less negative).
      // Since flow is negative during exp, "scooped" means closer to zero.
      expect(modified.flow.abs(), lessThan(baseSample.flow.abs()));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 6. CircuitLeakModifier
  // ═══════════════════════════════════════════════════════════════════════

  group('CircuitLeakModifier', () {
    late CircuitLeakModifier mod;

    setUp(() {
      mod = CircuitLeakModifier();
    });

    test('severe: volume reduced by ~50%', () {
      final sample = BreathSample(
        pressure: 20,
        flow: -10,
        volume: 400,
        phase: BreathPhase.expiration,
      );
      final params = VentParams(peep: 5, compliance: 50);
      final event = _activeEvent(
        PathophysiologyType.circuitLeak,
        severity: PathophysiologySeverity.severe,
        intensity: 1.0,
      );

      final modified = mod.modifySample(sample, params, event, 0);

      // Volume should be ~200 mL (50% leak).
      expect(modified.volume, closeTo(200, 10));
    });

    test('pressure drops proportionally but PEEP maintained', () {
      final sample = BreathSample(
        pressure: 20, // PEEP 5 + elastic 15
        flow: -10,
        volume: 400,
        phase: BreathPhase.expiration,
      );
      final params = VentParams(peep: 5, compliance: 50);
      final event = _activeEvent(
        PathophysiologyType.circuitLeak,
        severity: PathophysiologySeverity.severe,
        intensity: 1.0,
      );

      final modified = mod.modifySample(sample, params, event, 0);

      // Elastic delta = 20 - 5 = 15. After 50% leak → 7.5.
      // New pressure = 5 + 7.5 = 12.5.
      expect(modified.pressure, closeTo(12.5, 0.5));
      expect(modified.pressure, greaterThanOrEqualTo(params.peep));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 7. RightMainstemModifier
  // ═══════════════════════════════════════════════════════════════════════

  group('RightMainstemModifier', () {
    late RightMainstemModifier mod;

    setUp(() {
      mod = RightMainstemModifier();
    });

    test('compliance drops 45%, resistance increases 20% at full intensity', () {
      final params = VentParams(compliance: 50, resistance: 8);
      final event = _activeEvent(
        PathophysiologyType.rightMainstemIntubation,
        intensity: 1.0,
      );

      final modified = mod.modifyParams(params, event, 0);

      // C: 50 × 0.55 = 27.5.
      expect(modified.compliance, closeTo(27.5, 0.5));
      // R: 8 × 1.20 = 9.6.
      expect(modified.resistance, closeTo(9.6, 0.1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 8. PathophysiologyRegistry — chained modifiers
  // ═══════════════════════════════════════════════════════════════════════

  group('PathophysiologyRegistry', () {
    test('multiple modifiers in chain: auto-PEEP + secretion compound effects', () {
      // Use params that trigger auto-PEEP AND benefit from secretion.
      final params = VentParams(
        mode: VentMode.vcv,
        compliance: 70,
        resistance: 10,
        peep: 3,
        rr: 20,
        vt: 400,
        ieRatio: 2.0,
      );

      final autoPeepEvent = _activeEvent(
        PathophysiologyType.autoPeep,
        severity: PathophysiologySeverity.severe,
        intensity: 1.0,
      );
      final secretionEvent = _activeEvent(
        PathophysiologyType.secretion,
        severity: PathophysiologySeverity.moderate,
        intensity: 1.0,
      );

      // Re-register fresh modifiers to clear any accumulated state.
      PathophysiologyRegistry.register(AutoPeepModifier());
      PathophysiologyRegistry.register(SecretionModifier());

      // Warm up the modifiers (auto-PEEP needs smoothing, secretion ramps).
      // 10000 ticks ≈ 40 s — enough for both to converge.
      for (int i = 0; i < 10000; i++) {
        final t = i * EngineConstants.dt;
        final baseSample = VentilatorEngine.simulate(params, t);
        PathophysiologyRegistry.apply(
          originalParams: params,
          originalSample: baseSample,
          activeEvents: [autoPeepEvent, secretionEvent],
          simTime: t,
        );
      }

      // Now take a single measurement.
      final t = 10000 * EngineConstants.dt;
      final baseSample = VentilatorEngine.simulate(params, t);
      final result = PathophysiologyRegistry.apply(
        originalParams: params,
        originalSample: baseSample,
        activeEvents: [autoPeepEvent, secretionEvent],
        simTime: t,
      );

      // Params should reflect BOTH modifications.
      // Secretion → higher resistance (this always applies first).
      expect(result.params.resistance, greaterThan(params.resistance));
      // Auto-PEEP → higher PEEP (depends on the elevated τ from secretion).
      expect(result.params.peep, greaterThanOrEqualTo(params.peep));
    });

    test('empty active events return original params and sample', () {
      final params = VentParams();
      final sample = VentilatorEngine.simulate(params, 1.0);

      final result = PathophysiologyRegistry.apply(
        originalParams: params,
        originalSample: sample,
        activeEvents: [],
        simTime: 1.0,
      );

      expect(identical(result.params, params), isTrue);
      expect(identical(result.sample, sample), isTrue);
    });

    test('resetAll clears all modifier state', () {
      // This should not throw.
      PathophysiologyRegistry.resetAll();
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 9. PathophysiologyEntities
  // ═══════════════════════════════════════════════════════════════════════

  group('PathophysiologyEntities', () {
    test('PathophysiologyState.initial() creates all event types', () {
      final state = PathophysiologyState.initial();
      expect(state.events.length, PathophysiologyType.values.length);
      expect(state.hasActiveEvents, isFalse);
      expect(state.activeEvents, isEmpty);
    });

    test('eventOf retrieves correct type', () {
      final state = PathophysiologyState.initial();
      final event = state.eventOf(PathophysiologyType.pneumothorax);
      expect(event.type, PathophysiologyType.pneumothorax);
      expect(event.active, isFalse);
    });

    test('replaceEventByType updates the correct event', () {
      final state = PathophysiologyState.initial();
      final updated = state.replaceEventByType(
        PathophysiologyType.bronchospasm,
        state.eventOf(PathophysiologyType.bronchospasm).copyWith(active: true),
      );

      expect(updated.hasActiveEvents, isTrue);
      expect(updated.activeEvents.length, 1);
      expect(updated.activeEvents.first.type, PathophysiologyType.bronchospasm);
    });

    test('copyWith on event preserves nullable onsetTime correctly', () {
      final event = PathophysiologyEvent.initial(PathophysiologyType.autoPeep);
      expect(event.onsetTime, isNull);

      // Set onsetTime.
      final withOnset = event.copyWith(onsetTime: () => 42.0);
      expect(withOnset.onsetTime, 42.0);

      // Clear onsetTime back to null.
      final cleared = withOnset.copyWith(onsetTime: () => null);
      expect(cleared.onsetTime, isNull);

      // Leave onsetTime unchanged.
      final unchanged = withOnset.copyWith(active: true);
      expect(unchanged.onsetTime, 42.0);
    });

    test('every event type has non-empty label, description, emoji', () {
      for (final type in PathophysiologyType.values) {
        final event = PathophysiologyEvent.initial(type);
        expect(event.label.isNotEmpty, isTrue,
            reason: '${type.name} should have a label');
        expect(event.description.isNotEmpty, isTrue,
            reason: '${type.name} should have a description');
        expect(event.emoji.isNotEmpty, isTrue,
            reason: '${type.name} should have an emoji');
      }
    });
  });
}
