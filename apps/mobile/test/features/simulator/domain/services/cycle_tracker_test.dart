import 'package:flutter_test/flutter_test.dart';
import 'package:pocusapp/features/simulator/domain/entities/ventilator_entities.dart';
import 'package:pocusapp/features/simulator/domain/enums/ventilation_enums.dart';
import 'package:pocusapp/features/simulator/domain/services/cycle_tracker.dart';
import 'package:pocusapp/features/simulator/domain/services/ventilator_engine.dart';

void main() {
  group('CycleTracker', () {
    late CycleTracker tracker;

    setUp(() {
      tracker = CycleTracker(peep: 5, rr: 15);
    });

    test('initial metrics are zeroed', () {
      final m = tracker.currentMetrics;
      expect(m.pip, 0);
      expect(m.peep, 0);
      expect(m.vte, 0);
      expect(m.rr, 0);
    });

    test('tracks peak pressure during inspiration', () {
      // Feed increasing pressures during inspiration.
      for (var i = 0; i < 5; i++) {
        tracker.processSample(
          BreathSample(
            pressure: 10.0 + i,
            flow: 30,
            volume: 100.0 + i * 20,
            phase: BreathPhase.inspiration,
          ),
          i * 0.01,
          5,
        );
      }

      // Transition to expiration → freezes metrics.
      tracker.processSample(
        BreathSample(
          pressure: 5,
          flow: -20,
          volume: 180,
          phase: BreathPhase.expiration,
        ),
        0.05,
        5,
      );

      final m = tracker.currentMetrics;
      expect(m.pip, 14); // peak was 10+4=14
      expect(m.vte, 180); // peak volume during insp
      expect(m.peep, 5);
    });

    test('freezes metrics on inspiration→expiration transition', () {
      // First breath: inspiration.
      tracker.processSample(
        BreathSample(
          pressure: 20,
          flow: 40,
          volume: 400,
          phase: BreathPhase.inspiration,
        ),
        0,
        5,
      );

      // Metrics not yet frozen (still in inspiration).
      expect(tracker.currentMetrics.pip, 0);

      // Transition to expiration → freeze.
      tracker.processSample(
        BreathSample(
          pressure: 5,
          flow: -10,
          volume: 350,
          phase: BreathPhase.expiration,
        ),
        0.5,
        5,
      );

      expect(tracker.currentMetrics.pip, 20);
      expect(tracker.currentMetrics.vte, 400);
    });

    test('computes measured RR from inter-breath interval', () {
      // First breath onset.
      tracker.processSample(
        BreathSample(
          pressure: 20,
          flow: 40,
          volume: 400,
          phase: BreathPhase.inspiration,
        ),
        0,
        5,
      );
      tracker.processSample(
        BreathSample(
          pressure: 5,
          flow: -10,
          volume: 100,
          phase: BreathPhase.expiration,
        ),
        0.5,
        5,
      );

      // Second breath onset at t=4.0 → interval=4.0s → RR=15.
      tracker.processSample(
        BreathSample(
          pressure: 22,
          flow: 40,
          volume: 420,
          phase: BreathPhase.inspiration,
        ),
        4.0,
        5,
      );
      tracker.processSample(
        BreathSample(
          pressure: 5,
          flow: -10,
          volume: 100,
          phase: BreathPhase.expiration,
        ),
        4.5,
        5,
      );

      expect(tracker.currentMetrics.rr, 15);
    });

    test('uses set RR when no measured RR is available yet', () {
      tracker.processSample(
        BreathSample(
          pressure: 18,
          flow: 30,
          volume: 350,
          phase: BreathPhase.inspiration,
        ),
        0,
        5,
      );
      tracker.processSample(
        BreathSample(
          pressure: 5,
          flow: -10,
          volume: 100,
          phase: BreathPhase.expiration,
        ),
        0.5,
        5,
      );

      // First cycle — no measured RR yet, falls back to set RR (15).
      expect(tracker.currentMetrics.rr, 15);
    });

    test('updates metrics on each new cycle', () {
      // Cycle 1: PIP=25, Vte=500.
      tracker.processSample(
        BreathSample(
          pressure: 25,
          flow: 40,
          volume: 500,
          phase: BreathPhase.inspiration,
        ),
        0,
        5,
      );
      tracker.processSample(
        BreathSample(
          pressure: 5,
          flow: -10,
          volume: 50,
          phase: BreathPhase.expiration,
        ),
        1.0,
        5,
      );

      expect(tracker.currentMetrics.pip, 25);
      expect(tracker.currentMetrics.vte, 500);

      // Cycle 2: PIP=30, Vte=600 — metrics should update.
      tracker.processSample(
        BreathSample(
          pressure: 30,
          flow: 50,
          volume: 600,
          phase: BreathPhase.inspiration,
        ),
        4.0,
        5,
      );
      tracker.processSample(
        BreathSample(
          pressure: 5,
          flow: -10,
          volume: 50,
          phase: BreathPhase.expiration,
        ),
        5.0,
        5,
      );

      expect(tracker.currentMetrics.pip, 30);
      expect(tracker.currentMetrics.vte, 600);
    });

    test('reset clears all state', () {
      // Run a cycle.
      tracker.processSample(
        BreathSample(
          pressure: 22,
          flow: 40,
          volume: 450,
          phase: BreathPhase.inspiration,
        ),
        0,
        5,
      );
      tracker.processSample(
        BreathSample(
          pressure: 5,
          flow: -10,
          volume: 50,
          phase: BreathPhase.expiration,
        ),
        0.5,
        5,
      );
      expect(tracker.currentMetrics.pip, 22);

      // Reset.
      tracker.reset(8, 20);

      final m = tracker.currentMetrics;
      expect(m.pip, 0);
      expect(m.peep, 0);
      expect(m.vte, 0);
      expect(m.rr, 0);
    });

    test('ignores implausibly short inter-breath intervals', () {
      // First breath.
      tracker.processSample(
        BreathSample(
          pressure: 20,
          flow: 40,
          volume: 400,
          phase: BreathPhase.inspiration,
        ),
        0,
        5,
      );
      tracker.processSample(
        BreathSample(
          pressure: 5,
          flow: -10,
          volume: 50,
          phase: BreathPhase.expiration,
        ),
        0.2,
        5,
      );

      // Second breath at t=0.3 → interval=0.3s (<0.5) → ignored.
      tracker.processSample(
        BreathSample(
          pressure: 20,
          flow: 40,
          volume: 400,
          phase: BreathPhase.inspiration,
        ),
        0.3,
        5,
      );
      tracker.processSample(
        BreathSample(
          pressure: 5,
          flow: -10,
          volume: 50,
          phase: BreathPhase.expiration,
        ),
        0.5,
        5,
      );

      // measuredRr should still be 0, so fallback to setRr=15.
      expect(tracker.currentMetrics.rr, 15);
    });

    test('PEEP updates dynamically when passed new value', () {
      tracker.processSample(
        BreathSample(
          pressure: 20,
          flow: 40,
          volume: 400,
          phase: BreathPhase.inspiration,
        ),
        0,
        5,
      );

      // Transition with new PEEP=10.
      tracker.processSample(
        BreathSample(
          pressure: 10,
          flow: -10,
          volume: 50,
          phase: BreathPhase.expiration,
        ),
        0.5,
        10,
      );

      expect(tracker.currentMetrics.peep, 10);
    });

    group('integration with VentilatorEngine', () {
      test('completes 2 full VCV cycles with realistic metrics', () {
        final params = VentParams(
          mode: VentMode.vcv,
          compliance: 50,
          resistance: 8,
          peep: 5,
          rr: 15,
          vt: 500,
          pip: 25,
          ps: 10,
          fio2: 40,
          ieRatio: 2.0,
          patientEffort: 0,
        );

        final tracker = CycleTracker(peep: params.peep, rr: params.rr);
        final dt = EngineConstants.dt;
        final cycleDuration = params.totalCycleTime;

        // Run 2.5 cycles.
        final totalTime = cycleDuration * 2.5;
        var simTime = 0.0;

        while (simTime < totalTime) {
          final sample = VentilatorEngine.simulate(params, simTime);
          tracker.processSample(sample, simTime, params.peep);
          simTime += dt;
        }

        final m = tracker.currentMetrics;

        // PIP should be in realistic range for VCV (PEEP + Vt/C + Flow*R).
        expect(m.pip, greaterThan(10));
        expect(m.pip, lessThan(30));

        // VTE should be close to set Vt (500 mL).
        expect(m.vte, greaterThan(400));
        expect(m.vte, lessThan(600));

        // PEEP should match.
        expect(m.peep, 5);

        // RR should be close to 15 (derived from inter-breath interval).
        expect(m.rr, greaterThan(12));
        expect(m.rr, lessThan(18));
      });

      test('completes PCV cycles with volume limited by compliance', () {
        final params = VentParams(
          mode: VentMode.pcv,
          compliance: 20, // Low compliance (ARDS)
          resistance: 12,
          peep: 14,
          rr: 20,
          vt: 350,
          pip: 28,
          ps: 10,
          fio2: 80,
          ieRatio: 2.0,
          patientEffort: 0,
        );

        final tracker = CycleTracker(peep: params.peep, rr: params.rr);
        final dt = EngineConstants.dt;
        final cycleDuration = params.totalCycleTime;
        final totalTime = cycleDuration * 2.5;
        var simTime = 0.0;

        while (simTime < totalTime) {
          final sample = VentilatorEngine.simulate(params, simTime);
          tracker.processSample(sample, simTime, params.peep);
          simTime += dt;
        }

        final m = tracker.currentMetrics;

        // PIP should be close to PEEP + PIP setting (14 + 28 = 42).
        expect(m.pip, greaterThan(38));
        expect(m.pip, lessThan(46));

        // Theoretical Vt = C × ΔP = 20 × 28 = 560 mL (exponential fill).
        expect(m.vte, greaterThan(300));
        expect(m.vte, lessThan(600));

        expect(m.peep, 14);
      });
    });
  });
}
