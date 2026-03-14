import 'dart:math' as math;

import '../entities/ventilator_entities.dart';
import '../enums/ventilation_enums.dart';

/// Pure, stateless ventilator simulation engine.
///
/// Produces a single [BreathSample] for a given [VentParams] and elapsed
/// time within the respiratory cycle. Designed to be called at
/// [EngineConstants.dt] intervals (250 Hz) by an external loop.
///
/// Single-compartment RC lung model:
///   Paw = V / C + Flow × R + PEEP
///
/// where:
///   - V = instantaneous volume above FRC (L)
///   - C = compliance (L/cmH₂O)
///   - R = resistance (cmH₂O·s/L)
///   - PEEP = set end-expiratory pressure (cmH₂O)
///
/// **100 % pure Dart** — no Flutter, no UI, no mutable state.
abstract final class VentilatorEngine {
  /// Compute a single waveform sample at [time] seconds.
  ///
  /// [time] is automatically wrapped to [VentParams.totalCycleTime] so the
  /// caller may pass a continuously increasing wall-clock value.
  static BreathSample simulate(VentParams p, double time) {
    // APRV has its own two-phase cycle logic.
    if (p.mode == VentMode.aprv) return _aprvSimulate(p, time);

    final cycle = p.totalCycleTime;
    final t = time % cycle;
    final ti = p.inspTime;

    if (t < ti) {
      return switch (p.mode) {
        VentMode.vcv => _vcvInsp(p, t),
        VentMode.pcv => _pcvInsp(p, t),
        VentMode.psv => _psvInsp(p, t),
        VentMode.aprv => _pcvInsp(p, t), // unreachable, handled above
      };
    } else {
      return _expiration(p, t - ti, _vEndInsp(p));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Volume at end of inspiration (L) — needed for expiratory decay.
  // ═══════════════════════════════════════════════════════════════════════

  /// Computes the lung volume (litres) reached at the instant inspiration
  /// ends.  Used as the initial condition for the expiratory phase.
  static double _vEndInsp(VentParams p) {
    final cL = p.compliance / 1000.0; // mL/cmH₂O → L/cmH₂O
    final ti = p.inspTime;
    final tau = p.tau;

    return switch (p.mode) {
      // VCV: ventilator delivers exactly the set Vt.
      VentMode.vcv => p.vt / 1000.0,

      // PCV: exponential fill toward C × ΔP.
      VentMode.pcv => cL * p.pip * (1.0 - math.exp(-ti / tau)),

      // PSV: exponential fill with time-averaged effective drive.
      //   avg(drive) = PS + effort × 2/π  (sinusoidal average over [0, Ti]).
      VentMode.psv => cL *
          (p.ps + p.patientEffort * 2.0 / math.pi) *
          (1.0 - math.exp(-ti / tau)),

      // APRV: volume at end of P-high phase.
      VentMode.aprv => cL * p.pHigh * (1.0 - math.exp(-ti / tau)),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════
  // VCV — Volume-Controlled Ventilation (inspiration)
  // ═══════════════════════════════════════════════════════════════════════
  //
  // Operator sets: Vt, RR, PEEP, I:E.
  // Dependent variable: airway pressure.
  //
  // Inspiration: constant flow → volume ramps linearly.
  // Paw = PEEP + V/C + Flow×R

  static BreathSample _vcvInsp(VentParams p, double t) {
    final cL = p.compliance / 1000.0; // L/cmH₂O
    final r = p.resistance; // cmH₂O·s/L
    final ti = p.inspTime;

    // Constant inspiratory flow (L/s).
    final flowLs = (p.vt / 1000.0) / ti;

    // Volume ramps linearly (L), capped at set Vt.
    final volL = math.min(flowLs * t, p.vt / 1000.0);

    // Equation of motion: Paw = PEEP + V/C + Flow×R.
    final pressure = p.peep + volL / cL + flowLs * r;

    return BreathSample(
      pressure: pressure,
      flow: flowLs * 60.0, // L/s → L/min
      volume: volL * 1000.0, // L → mL
      phase: BreathPhase.inspiration,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PCV — Pressure-Controlled Ventilation (inspiration)
  // ═══════════════════════════════════════════════════════════════════════
  //
  // Operator sets: driving pressure (pip above PEEP), RR, I:E, PEEP.
  // Dependent variable: tidal volume.
  //
  // Pressure held constant → volume fills exponentially:
  //   V(t) = C × ΔP × (1 − e^(−t/τ))

  static BreathSample _pcvInsp(VentParams p, double t) {
    final cL = p.compliance / 1000.0;
    final r = p.resistance;
    final tau = p.tau;
    final dp = p.pip; // driving pressure above PEEP

    // Volume fills exponentially (L).
    final volL = cL * dp * (1.0 - math.exp(-t / tau));

    // Flow = (ΔP − V/C) / R  (L/s).
    final flowLs = (dp - volL / cL) / r;

    // Airway pressure is the set target (square wave).
    final pressure = p.peep + dp;

    return BreathSample(
      pressure: pressure,
      flow: flowLs * 60.0,
      volume: volL * 1000.0,
      phase: BreathPhase.inspiration,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PSV — Pressure-Support Ventilation (inspiration)
  // ═══════════════════════════════════════════════════════════════════════
  //
  // Patient-triggered, pressure-assisted breaths.
  // Patient effort modelled as sinusoidal muscle pressure:
  //   effectiveDrive = PS + max(0, effort × sin(π × t / Ti))
  //
  // The machine supplies PS (displayed on the airway pressure trace).
  // The patient's effort acts internally, increasing the transmural
  // gradient that drives flow without appearing on the Paw trace.

  static BreathSample _psvInsp(VentParams p, double t) {
    final cL = p.compliance / 1000.0;
    final r = p.resistance;
    final tau = p.tau;
    final ti = p.inspTime;

    // Sinusoidal patient effort (peaks at mid-inspiration).
    final effort =
        math.max(0.0, p.patientEffort * math.sin(math.pi * t / ti));
    final effectiveDrive = p.ps + effort;

    // Volume (L): RC fill with instantaneous effective drive.
    final volL = cL * effectiveDrive * (1.0 - math.exp(-t / tau));

    // Flow (L/s).
    final flowLs = (effectiveDrive - volL / cL) / r;

    // Displayed airway pressure = PEEP + PS (machine pressure only;
    // muscle effort is not visible on the ventilator screen).
    final pressure = p.peep + p.ps;

    return BreathSample(
      pressure: pressure,
      flow: flowLs * 60.0,
      volume: volL * 1000.0,
      phase: BreathPhase.inspiration,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Expiration — passive RC decay (all modes)
  // ═══════════════════════════════════════════════════════════════════════
  //
  // V(t) = V_end × e^(−t/τ)
  // Flow  = −V_end / τ × e^(−t/τ)   (negative = out of lungs)
  // Paw   = PEEP + V/C

  // ═══════════════════════════════════════════════════════════════════════
  // APRV — Airway Pressure Release Ventilation
  // ═══════════════════════════════════════════════════════════════════════
  //
  // Two pressure levels (P-high / P-low) with time-cycling (T-high / T-low).
  //
  // P-high phase (T-high): lung fills exponentially toward C × P-high.
  //   V(t) = C × P-high × (1 − e^(−t/τ))
  //   Optional spontaneous breathing overlay adds small tidal volumes.
  //
  // P-low (release) phase (T-low): lung empties exponentially from V_end.
  //   V(t) = V_end × e^(−t/τ)
  //   Release is intentionally brief to maintain recruited volume.

  static BreathSample _aprvSimulate(VentParams p, double time) {
    final cycle = p.tHigh + p.tLow;
    final t = time % cycle;
    final cL = p.compliance / 1000.0;
    final tau = p.tau;

    if (t < p.tHigh) {
      // ── P-high phase ────────────────────────────────────────────────
      final dp = p.pHigh; // driving pressure above atmospheric
      final volL = cL * dp * (1.0 - math.exp(-t / tau));
      final flowLs = (dp - volL / cL) / p.resistance;

      // Spontaneous breathing overlay during P-high.
      double spontVol = 0;
      double spontFlow = 0;
      if (p.spontaneousRR > 0) {
        final spontCycle = 60.0 / p.spontaneousRR;
        final tSpont = t % spontCycle;
        final spontTi = spontCycle / 3.0; // 1:2 ratio for spontaneous
        if (tSpont < spontTi) {
          // Small spontaneous tidal breath (~3 cmH₂O effort).
          const spontEffort = 3.0;
          spontVol = cL * spontEffort * (1.0 - math.exp(-tSpont / tau));
          spontFlow = (spontEffort - spontVol / cL) / p.resistance;
        } else {
          final spontExp = tSpont - spontTi;
          final spontVEnd = cL * 3.0 * (1.0 - math.exp(-spontTi / tau));
          spontVol = spontVEnd * math.exp(-spontExp / tau);
          spontFlow = -spontVEnd / tau * math.exp(-spontExp / tau);
        }
      }

      final totalVol = volL + spontVol;
      final totalFlow = flowLs + spontFlow;

      return BreathSample(
        pressure: p.pHigh,
        flow: totalFlow * 60.0,
        volume: totalVol * 1000.0,
        phase: BreathPhase.inspiration,
      );
    } else {
      // ── P-low (release) phase ───────────────────────────────────────
      final tRel = t - p.tHigh;
      // Volume at end of P-high phase.
      final vEndL = cL * p.pHigh * (1.0 - math.exp(-p.tHigh / tau));
      // Target volume at P-low equilibrium.
      final vTargetL = cL * p.pLow;
      // Exponential decay from vEnd toward vTarget.
      final volL = vTargetL + (vEndL - vTargetL) * math.exp(-tRel / tau);
      final flowLs = -(vEndL - vTargetL) / tau * math.exp(-tRel / tau);

      final pressure = p.pLow + (volL - vTargetL) / cL;

      return BreathSample(
        pressure: pressure.clamp(p.pLow, p.pHigh),
        flow: flowLs * 60.0,
        volume: volL * 1000.0,
        phase: BreathPhase.expiration,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Expiration — passive RC decay (all modes except APRV)
  // ═══════════════════════════════════════════════════════════════════════

  static BreathSample _expiration(VentParams p, double tExp, double vEndL) {
    final cL = p.compliance / 1000.0;
    final tau = p.tau;

    final fraction = math.exp(-tExp / tau);

    // Volume decays exponentially toward zero (L).
    final volL = vEndL * fraction;

    // Expiratory flow is negative (L/s).
    final flowLs = -vEndL / tau * fraction;

    // Pressure = PEEP + elastic recoil.
    final pressure = p.peep + volL / cL;

    return BreathSample(
      pressure: pressure,
      flow: flowLs * 60.0, // L/s → L/min
      volume: volL * 1000.0, // L → mL
      phase: BreathPhase.expiration,
    );
  }
}
