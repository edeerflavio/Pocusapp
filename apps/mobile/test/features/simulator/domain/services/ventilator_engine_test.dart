import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:pocusapp/features/simulator/domain/entities/ventilator_entities.dart';
import 'package:pocusapp/features/simulator/domain/enums/ventilation_enums.dart';
import 'package:pocusapp/features/simulator/domain/services/ventilator_engine.dart';

void main() {
  // ── Helper ─────────────────────────────────────────────────────────────

  /// Collects samples across one full breath cycle at EngineConstants.dt
  /// resolution and returns them as a list.
  List<BreathSample> sampleFullCycle(VentParams p) {
    final dt = EngineConstants.dt;
    final total = p.totalCycleTime;
    final samples = <BreathSample>[];
    for (double t = 0; t < total; t += dt) {
      samples.add(VentilatorEngine.simulate(p, t));
    }
    return samples;
  }

  double peakPressure(List<BreathSample> s) =>
      s.fold<double>(0, (m, e) => e.pressure > m ? e.pressure : m);

  double peakVolumeMl(List<BreathSample> s) =>
      s.fold<double>(0, (m, e) => e.volume > m ? e.volume : m);

  // ═════════════════════════════════════════════════════════════════════════
  // VCV Tests
  // ═════════════════════════════════════════════════════════════════════════

  group('VCV — Volume-Controlled Ventilation', () {
    const p = VentParams(
      mode: VentMode.vcv,
      compliance: 50,
      resistance: 8,
      peep: 5,
      vt: 500,
      rr: 14,
      ieRatio: 2.0,
    );

    late List<BreathSample> samples;
    setUpAll(() => samples = sampleFullCycle(p));

    test('PIP is in clinically expected range (15–25 cmH₂O)', () {
      final pip = peakPressure(samples);
      // PIP = PEEP + Vt/C + Flow×R
      //     = 5 + (0.5 L / 0.05 L/cmH₂O) + (flow × 8)
      // flow = 0.5 / Ti; Ti = (60/14)/(1+2) ≈ 1.43 s; flow ≈ 0.35 L/s
      // PIP ≈ 5 + 10 + 2.8 ≈ 17.8
      expect(pip, greaterThanOrEqualTo(15));
      expect(pip, lessThanOrEqualTo(25));
    });

    test('peak volume ≈ set Vt (500 mL)', () {
      final vMax = peakVolumeMl(samples);
      expect(vMax, closeTo(500, 10));
    });

    test('pressure at t=0 ≈ PEEP + Flow×R (resistive only, no elastic)', () {
      final s0 = VentilatorEngine.simulate(p, 0.0);
      // At t=0: V=0 → elastic = 0, P = PEEP + Flow×R
      final flow = (p.vt / 1000.0) / p.inspTime;
      final expected = p.peep + flow * p.resistance;
      expect(s0.pressure, closeTo(expected, 0.5));
    });

    test('all inspiratory samples have positive flow', () {
      final inspSamples =
          samples.where((s) => s.phase == BreathPhase.inspiration);
      for (final s in inspSamples) {
        expect(s.flow, greaterThan(0));
      }
    });

    test('all expiratory samples have negative flow', () {
      final expSamples =
          samples.where((s) => s.phase == BreathPhase.expiration);
      for (final s in expSamples) {
        expect(s.flow, lessThanOrEqualTo(0));
      }
    });

    test('pressure never drops below PEEP', () {
      for (final s in samples) {
        expect(s.pressure, greaterThanOrEqualTo(p.peep - 0.01));
      }
    });

    test('minute ventilation ≈ Vt × RR / 1000', () {
      // MV = 500 × 14 / 1000 = 7.0 L/min
      final vMax = peakVolumeMl(samples);
      final mv = vMax * p.rr / 1000.0;
      expect(mv, closeTo(7.0, 0.5));
    });

    test('time wrapping: t and t + totalCycleTime give identical results', () {
      const t = 0.5;
      final s1 = VentilatorEngine.simulate(p, t);
      final s2 = VentilatorEngine.simulate(p, t + p.totalCycleTime);
      expect(s1.pressure, closeTo(s2.pressure, 0.001));
      expect(s1.flow, closeTo(s2.flow, 0.001));
      expect(s1.volume, closeTo(s2.volume, 0.001));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // PCV Tests
  // ═════════════════════════════════════════════════════════════════════════

  group('PCV — Pressure-Controlled Ventilation', () {
    // Simulate ARDS-like low compliance: C=20, driving pressure=14,
    // PEEP=14 → total target = 28 cmH₂O.
    const p = VentParams(
      mode: VentMode.pcv,
      compliance: 20,
      resistance: 10,
      peep: 14,
      pip: 14, // driving pressure above PEEP
      rr: 20,
      ieRatio: 2.0,
    );

    late List<BreathSample> samples;
    setUpAll(() => samples = sampleFullCycle(p));

    test('inspiratory pressure = PEEP + pip (square wave)', () {
      final inspSamples =
          samples.where((s) => s.phase == BreathPhase.inspiration);
      for (final s in inspSamples) {
        expect(s.pressure, closeTo(p.peep + p.pip, 0.01));
      }
    });

    test('achieved Vt < 350 mL (low compliance limits filling)', () {
      // Vmax = C × ΔP = 20 × 14 = 280 mL (at infinite time).
      // With finite Ti, volume is even less.
      final vMax = peakVolumeMl(samples);
      expect(vMax, lessThan(350));
    });

    test('achieved Vt ≈ C × ΔP × (1 − e^(-Ti/τ))', () {
      final tau = p.tau; // 10 × 0.020 = 0.2 s
      final ti = p.inspTime;
      final expectedMl =
          (p.compliance / 1000.0) * p.pip * (1 - _exp(-ti / tau)) * 1000;
      final vMax = peakVolumeMl(samples);
      expect(vMax, closeTo(expectedMl, 5));
    });

    test('higher compliance → higher Vt', () {
      const highC = VentParams(
        mode: VentMode.pcv,
        compliance: 60,
        resistance: 10,
        peep: 14,
        pip: 14,
        rr: 20,
      );
      const lowC = VentParams(
        mode: VentMode.pcv,
        compliance: 20,
        resistance: 10,
        peep: 14,
        pip: 14,
        rr: 20,
      );
      final highV = peakVolumeMl(sampleFullCycle(highC));
      final lowV = peakVolumeMl(sampleFullCycle(lowC));
      expect(highV, greaterThan(lowV));
    });

    test('pressure never drops below PEEP', () {
      for (final s in samples) {
        expect(s.pressure, greaterThanOrEqualTo(p.peep - 0.01));
      }
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // PSV Tests
  // ═════════════════════════════════════════════════════════════════════════

  group('PSV — Pressure-Support Ventilation', () {
    const p = VentParams(
      mode: VentMode.psv,
      compliance: 50,
      resistance: 5,
      peep: 5,
      ps: 10,
      patientEffort: 4,
      rr: 18,
      ieRatio: 2.0,
    );

    late List<BreathSample> samples;
    setUpAll(() => samples = sampleFullCycle(p));

    test('displayed airway pressure = PEEP + PS during inspiration', () {
      final inspSamples =
          samples.where((s) => s.phase == BreathPhase.inspiration);
      for (final s in inspSamples) {
        expect(s.pressure, closeTo(p.peep + p.ps, 0.01));
      }
    });

    test('patient effort increases achieved Vt vs no effort', () {
      const withEffort = VentParams(
        mode: VentMode.psv,
        compliance: 50,
        resistance: 5,
        peep: 5,
        ps: 10,
        patientEffort: 5,
        rr: 18,
      );
      const noEffort = VentParams(
        mode: VentMode.psv,
        compliance: 50,
        resistance: 5,
        peep: 5,
        ps: 10,
        patientEffort: 0,
        rr: 18,
      );
      final withV = peakVolumeMl(sampleFullCycle(withEffort));
      final noV = peakVolumeMl(sampleFullCycle(noEffort));
      expect(withV, greaterThan(noV));
    });

    test('peak volume occurs during inspiration, not expiration', () {
      double maxInspVol = 0;
      double maxExpVol = 0;
      for (final s in samples) {
        if (s.phase == BreathPhase.inspiration && s.volume > maxInspVol) {
          maxInspVol = s.volume;
        }
        if (s.phase == BreathPhase.expiration && s.volume > maxExpVol) {
          maxExpVol = s.volume;
        }
      }
      // Expiratory max should be at the very start of expiration
      // (== end-insp volume), which equals the first expiratory sample.
      // But the peak during inspiration should be >= expiration start.
      expect(maxInspVol, greaterThanOrEqualTo(maxExpVol - 1));
    });

    test('pressure never drops below PEEP', () {
      for (final s in samples) {
        expect(s.pressure, greaterThanOrEqualTo(p.peep - 0.01));
      }
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Cross-mode: pressure ≥ PEEP invariant
  // ═════════════════════════════════════════════════════════════════════════

  group('Pressure ≥ PEEP invariant (all modes)', () {
    const modes = [
      VentParams(mode: VentMode.vcv, peep: 5),
      VentParams(mode: VentMode.pcv, peep: 10),
      VentParams(mode: VentMode.psv, peep: 8, patientEffort: 3),
    ];

    for (final p in modes) {
      test('${p.mode.shortLabel} with PEEP=${p.peep}', () {
        final samples = sampleFullCycle(p);
        for (final s in samples) {
          expect(s.pressure, greaterThanOrEqualTo(p.peep - 0.01),
              reason:
                  '${p.mode.shortLabel} pressure ${s.pressure} < PEEP ${p.peep}');
        }
      });
    }
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Auto-PEEP / Air trapping
  // ═════════════════════════════════════════════════════════════════════════

  group('Auto-PEEP (air trapping)', () {
    test('high resistance + high RR → residual volume at end-expiration', () {
      const p = VentParams(
        mode: VentMode.vcv,
        compliance: 80,
        resistance: 20,
        peep: 5,
        vt: 500,
        rr: 30,
        ieRatio: 1.0, // 1:1 → short expiratory time
      );
      // τ = 20 × 0.080 = 1.6 s; Te = (60/30)/(1+1) = 1.0 s
      // Fraction remaining = e^(-1.0/1.6) ≈ 0.535 → lots of trapped gas.
      final samples = sampleFullCycle(p);
      final lastSample = samples.last;
      // Volume at end of cycle should be significantly > 0 (trapped gas).
      expect(lastSample.volume, greaterThan(50));
    });

    test('normal mechanics + low RR → negligible residual volume', () {
      const p = VentParams(
        mode: VentMode.vcv,
        compliance: 50,
        resistance: 5,
        peep: 5,
        vt: 450,
        rr: 12,
        ieRatio: 2.0,
      );
      // τ = 5 × 0.050 = 0.25 s; Te = (60/12)×(2/3) = 3.33 s
      // Fraction = e^(-3.33/0.25) ≈ 0.0000 → essentially no trapping.
      final samples = sampleFullCycle(p);
      final lastSample = samples.last;
      expect(lastSample.volume, lessThan(1.0));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Phase transitions
  // ═════════════════════════════════════════════════════════════════════════

  group('Phase transitions', () {
    const p = VentParams(mode: VentMode.vcv, rr: 14, ieRatio: 2.0);

    test('inspiration at t=0', () {
      final s = VentilatorEngine.simulate(p, 0.0);
      expect(s.phase, BreathPhase.inspiration);
    });

    test('expiration at t = inspTime + 0.01', () {
      final s = VentilatorEngine.simulate(p, p.inspTime + 0.01);
      expect(s.phase, BreathPhase.expiration);
    });

    test('inspiration again after full cycle wrap', () {
      final s = VentilatorEngine.simulate(p, p.totalCycleTime + 0.001);
      expect(s.phase, BreathPhase.inspiration);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // VentParams derived values
  // ═════════════════════════════════════════════════════════════════════════

  group('VentParams derived values', () {
    test('tau = R × C / 1000', () {
      const p = VentParams(compliance: 50, resistance: 10);
      expect(p.tau, closeTo(0.5, 0.001));
    });

    test('totalCycleTime = 60 / RR', () {
      const p = VentParams(rr: 20);
      expect(p.totalCycleTime, closeTo(3.0, 0.001));
    });

    test('I:E ratio splits cycle correctly', () {
      const p = VentParams(rr: 12, ieRatio: 2.0);
      // Total = 5 s, Ti = 5/(1+2) ≈ 1.667, Te ≈ 3.333
      expect(p.inspTime, closeTo(1.667, 0.01));
      expect(p.expTime, closeTo(3.333, 0.01));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Clinical scenario: ARDS protective ventilation
  // ═════════════════════════════════════════════════════════════════════════

  group('Clinical scenario: ARDS with PCV', () {
    // Moderate ARDS: C=25, R=8, PEEP=12, ΔP=14, RR=22
    const p = VentParams(
      mode: VentMode.pcv,
      compliance: 25,
      resistance: 8,
      peep: 12,
      pip: 14,
      rr: 22,
      ieRatio: 2.0,
    );

    late List<BreathSample> samples;
    setUpAll(() => samples = sampleFullCycle(p));

    test('peak pressure = PEEP + ΔP = 26', () {
      expect(peakPressure(samples), closeTo(26, 0.1));
    });

    test('Vt < 400 mL (reduced compliance limits volume)', () {
      // Vmax = 25 × 14 = 350 mL; with finite Ti, slightly less.
      expect(peakVolumeMl(samples), lessThan(400));
    });

    test('driving pressure ≤ 15 cmH₂O (ARDS safety)', () {
      expect(p.pip, lessThanOrEqualTo(15));
    });
  });
}

double _exp(double x) => math.exp(x);
