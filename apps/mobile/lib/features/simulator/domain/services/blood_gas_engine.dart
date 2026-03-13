import 'dart:math' as math;

import '../entities/ventilator_entities.dart';

// ═══════════════════════════════════════════════════════════════════════════
// BloodGasEngine — dynamic arterial blood gas simulation
// ═══════════════════════════════════════════════════════════════════════════

/// Pure Dart engine that computes dynamic arterial blood gas values from
/// current ventilator parameters and patient data.
///
/// ## Models
///
/// ### CO₂ elimination (washout)
///
/// Steady-state:  PaCO₂_target = (VCO₂ / VA) × 863
///
/// Where VCO₂ = CO₂ production (≈ 200 mL/min), VA = alveolar ventilation
/// (L/min), and 863 is the standard conversion constant (STPD → BTPS).
///
/// The current PaCO₂ approaches the target exponentially:
///
///     PaCO₂(t+dt) = PaCO₂(t) + (target − current) × (1 − e^(−dt/τ))
///
/// τ = 45 s models the body CO₂ stores (FRC, tissue, blood bicarbonate
/// buffer). This gives clinically realistic 30–60 s response to changes
/// in RR or VT.
///
/// ### Oxygenation
///
/// Simplified alveolar gas equation:
///
///     PAO₂ = FiO₂ × (Patm − PH₂O) − PaCO₂ / RQ
///
/// PaO₂ = PAO₂ − A-a gradient, where the gradient models shunt/V-Q
/// mismatch as a function of compliance (lower C → more shunt).
///
/// ### Acid-base
///
/// pH from Henderson-Hasselbalch:  pH = 6.1 + log₁₀(HCO₃ / (0.03 × PaCO₂))
///
/// HCO₃ uses a slow renal compensation model (hours-scale) — in the
/// simulator's timeframe (minutes), it stays nearly constant unless
/// explicitly changed.
///
/// ### SaO₂
///
/// Hill equation approximation of the oxyhemoglobin dissociation curve:
///
///     SaO₂ = PaO₂^2.7 / (PaO₂^2.7 + 26.6^2.7) × 100
///
/// ### Weaning criteria (PSV mode)
///
/// - **RSBI (Tobin Index)** = RR / (Vt / 1000)  [breaths/min/L]
///     - < 105: weaning likely to succeed
///     - ≥ 105: weaning likely to fail
/// - P/F ratio, PEEP, FiO₂, minute ventilation thresholds
///
/// **100 % pure Dart** — no Flutter, no Riverpod.
abstract final class BloodGasEngine {
  // ── Constants ──────────────────────────────────────────────────────────

  /// CO₂ production (L/min STPD). Normal resting adult ≈ 200 mL/min.
  static const double _vco2 = 0.200;

  /// STPD→BTPS conversion constant for the alveolar gas equation.
  static const double _k = 863.0;

  /// CO₂ washout time constant (seconds).
  ///
  /// Models the body's CO₂ stores (FRC gas, dissolved CO₂, bicarbonate
  /// buffer). 45 s gives a half-life of ~31 s, producing clinically
  /// realistic 30–60 s equilibration after ventilator changes.
  static const double _tauCO2 = 45.0;

  /// Atmospheric pressure (mmHg).
  static const double _patm = 760.0;

  /// Water vapour pressure at body temperature (mmHg).
  static const double _ph2o = 47.0;

  /// Respiratory quotient.
  static const double _rq = 0.8;

  /// Hill equation P50 for standard hemoglobin (mmHg).
  static const double _p50 = 26.6;

  /// Hill coefficient for the oxyhemoglobin dissociation curve.
  static const double _hillN = 2.7;

  // ── Dynamic ABG computation ────────────────────────────────────────────

  /// Compute the target steady-state PaCO₂ for the current ventilation.
  ///
  /// Returns the value PaCO₂ would converge to if the current VA were
  /// maintained indefinitely.
  static double targetPaCO2({
    required VentParams params,
    required PatientData patient,
  }) {
    final va = alveolarVentilation(params: params, patient: patient);
    if (va <= 0.01) return 120.0; // Apnea → max CO₂
    return (_vco2 / va) * _k;
  }

  /// Step the PaCO₂ towards its target using exponential washout.
  ///
  /// [currentPaCO2]: current value (mmHg).
  /// [dt]: time elapsed since last update (seconds).
  ///
  /// Returns the new PaCO₂ after the washout step.
  static double stepPaCO2({
    required double currentPaCO2,
    required VentParams params,
    required PatientData patient,
    required double dt,
  }) {
    final target = targetPaCO2(params: params, patient: patient);
    final alpha = 1.0 - math.exp(-dt / _tauCO2);
    final newPaCO2 = currentPaCO2 + (target - currentPaCO2) * alpha;
    return newPaCO2.clamp(10.0, 120.0);
  }

  /// Compute PaO₂ from the alveolar gas equation with a shunt model.
  ///
  /// The A-a gradient increases as compliance decreases (modeling
  /// shunt / V-Q mismatch in diseased lungs):
  ///
  ///     A-a gradient = baseGradient + shuntComponent
  ///     baseGradient = age/4 + 4
  ///     shuntComponent = max(0, (50 - compliance) × 1.5)
  ///
  /// So a normal lung (C=50) has gradient ≈ 16.5 mmHg (age 50), while
  /// ARDS (C=20) has gradient ≈ 61.5 mmHg.
  static double computePaO2({
    required VentParams params,
    required PatientData patient,
    required double paco2,
  }) {
    final fio2Frac = params.fio2 / 100.0;

    // Alveolar gas equation.
    final pao2Alv = fio2Frac * (_patm - _ph2o) - paco2 / _rq;

    // A-a gradient model.
    final baseGradient = patient.age / 4.0 + 4.0;
    final shuntComponent =
        math.max(0.0, (50.0 - params.compliance) * 1.5);
    final aaGradient = baseGradient + shuntComponent;

    // PEEP benefit: each cmH₂O of PEEP above 5 reduces shunt by ~2 mmHg.
    final peepBenefit = math.max(0.0, (params.peep - 5) * 2.0);

    final pao2 = pao2Alv - aaGradient + peepBenefit;
    return pao2.clamp(20.0, 600.0);
  }

  /// Compute SaO₂ from PaO₂ using the Hill equation.
  static double computeSaO2(double pao2) {
    final pn = math.pow(pao2, _hillN);
    final p50n = math.pow(_p50, _hillN);
    final sao2 = (pn / (pn + p50n)) * 100.0;
    return sao2.clamp(50.0, 100.0);
  }

  /// Compute pH from Henderson-Hasselbalch equation.
  ///
  ///     pH = 6.1 + log₁₀(HCO₃ / (0.03 × PaCO₂))
  static double computePH({
    required double paco2,
    required double hco3,
  }) {
    if (paco2 <= 0 || hco3 <= 0) return 7.40;
    final ph = 6.1 + math.log(hco3 / (0.03 * paco2)) / math.ln10;
    return ph.clamp(6.80, 7.80);
  }

  /// Compute HCO₃ with slow renal compensation.
  ///
  /// In acute respiratory disturbances, HCO₃ changes ~1 mEq/L per
  /// 10 mmHg PaCO₂ change (from 40 mmHg baseline). The compensation
  /// is very slow (hours), so we model a slight drift per step.
  static double stepHCO3({
    required double currentHCO3,
    required double paco2,
    required double dt,
  }) {
    // Target HCO₃ for acute compensation.
    final paco2Delta = paco2 - 40.0;
    final targetHCO3 = 24.0 + paco2Delta * 0.1; // 1 mEq/L per 10 mmHg

    // Very slow drift — τ_renal ≈ 3600 s (1 hour).
    const tauRenal = 3600.0;
    final alpha = 1.0 - math.exp(-dt / tauRenal);
    final newHCO3 = currentHCO3 + (targetHCO3 - currentHCO3) * alpha;
    return newHCO3.clamp(5.0, 50.0);
  }

  // ── Alveolar ventilation ───────────────────────────────────────────────

  /// Alveolar ventilation (L/min).
  ///
  ///     VA = (Vt − Vd) × RR / 1000
  ///
  /// Dead space Vd ≈ 2.2 mL/kg IBW.
  static double alveolarVentilation({
    required VentParams params,
    required PatientData patient,
  }) {
    final vd = 2.2 * patient.ibw;
    final effectiveVt = math.max(0.0, params.vt - vd);
    return effectiveVt * params.rr / 1000.0;
  }

  // ── Weaning criteria (PSV) ─────────────────────────────────────────────

  /// Compute the Rapid Shallow Breathing Index (RSBI / Tobin Index).
  ///
  ///     RSBI = RR / (Vt / 1000)  [breaths/min/L]
  ///
  /// - < 105: weaning likely to succeed (sensitivity ~97%)
  /// - ≥ 105: weaning likely to fail
  ///
  /// Uses measured Vte from [CycleMetrics] when available.
  static double rsbi({
    required int rr,
    required int vte,
  }) {
    if (vte <= 0) return 999.0;
    return rr / (vte / 1000.0);
  }

  /// Evaluate all weaning readiness criteria.
  ///
  /// Returns a [WeaningAssessment] with individual criterion results
  /// and an overall readiness score.
  static WeaningAssessment assessWeaning({
    required VentParams params,
    required CycleMetrics metrics,
    required double pao2,
    required double paco2,
    required double ph,
  }) {
    final fio2Frac = params.fio2 / 100.0;
    final pfRatio = pao2 / fio2Frac;
    final vte = metrics.vte > 0 ? metrics.vte : params.vt;
    final rsbiValue = rsbi(rr: metrics.rr > 0 ? metrics.rr : params.rr, vte: vte);
    final mv = metrics.minuteVolume > 0
        ? metrics.minuteVolume
        : params.vt * params.rr / 1000.0;

    final criteria = <WeaningCriterion>[
      WeaningCriterion(
        name: 'RSBI (Tobin)',
        value: rsbiValue.toStringAsFixed(0),
        unit: 'resp/min/L',
        target: '< 105',
        passed: rsbiValue < 105,
      ),
      WeaningCriterion(
        name: 'P/F',
        value: pfRatio.toStringAsFixed(0),
        unit: '',
        target: '> 200',
        passed: pfRatio > 200,
      ),
      WeaningCriterion(
        name: 'PEEP',
        value: params.peep.toStringAsFixed(0),
        unit: 'cmH₂O',
        target: '≤ 8',
        passed: params.peep <= 8,
      ),
      WeaningCriterion(
        name: 'FiO₂',
        value: '${params.fio2}',
        unit: '%',
        target: '≤ 40',
        passed: params.fio2 <= 40,
      ),
      WeaningCriterion(
        name: 'VM',
        value: mv.toStringAsFixed(1),
        unit: 'L/min',
        target: '< 15',
        passed: mv < 15,
      ),
      WeaningCriterion(
        name: 'pH',
        value: ph.toStringAsFixed(2),
        unit: '',
        target: '7.30–7.50',
        passed: ph >= 7.30 && ph <= 7.50,
      ),
      WeaningCriterion(
        name: 'PaCO₂',
        value: paco2.toStringAsFixed(0),
        unit: 'mmHg',
        target: '< 50',
        passed: paco2 < 50,
      ),
    ];

    final passedCount = criteria.where((c) => c.passed).length;
    final readyToWean = passedCount == criteria.length;

    return WeaningAssessment(
      criteria: criteria,
      passedCount: passedCount,
      totalCount: criteria.length,
      readyToWean: readyToWean,
      rsbi: rsbiValue,
    );
  }

  // ── Full snapshot ──────────────────────────────────────────────────────

  /// Generate a complete [DynamicAbgResult] from current simulation state.
  static DynamicAbgResult computeSnapshot({
    required double paco2,
    required double hco3,
    required VentParams params,
    required PatientData patient,
  }) {
    final pao2 = computePaO2(
      params: params,
      patient: patient,
      paco2: paco2,
    );
    final sao2 = computeSaO2(pao2);
    final ph = computePH(paco2: paco2, hco3: hco3);
    final fio2Frac = params.fio2 / 100.0;
    final pfRatio = pao2 / fio2Frac;
    final va = alveolarVentilation(params: params, patient: patient);
    final mv = params.vt * params.rr / 1000.0;

    return DynamicAbgResult(
      ph: ph,
      paco2: paco2,
      pao2: pao2,
      hco3: hco3,
      sao2: sao2,
      pfRatio: pfRatio,
      alveolarVentilation: va,
      minuteVolume: mv,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Data classes
// ═══════════════════════════════════════════════════════════════════════════

/// Dynamic blood gas result — a snapshot of computed ABG values.
class DynamicAbgResult {
  const DynamicAbgResult({
    required this.ph,
    required this.paco2,
    required this.pao2,
    required this.hco3,
    required this.sao2,
    required this.pfRatio,
    required this.alveolarVentilation,
    required this.minuteVolume,
  });

  factory DynamicAbgResult.initial() => const DynamicAbgResult(
        ph: 7.40,
        paco2: 40.0,
        pao2: 90.0,
        hco3: 24.0,
        sao2: 97.0,
        pfRatio: 450.0,
        alveolarVentilation: 4.9,
        minuteVolume: 6.3,
      );

  final double ph;
  final double paco2;
  final double pao2;
  final double hco3;
  final double sao2;
  final double pfRatio;
  final double alveolarVentilation;
  final double minuteVolume;
}

/// Single weaning readiness criterion with pass/fail.
class WeaningCriterion {
  const WeaningCriterion({
    required this.name,
    required this.value,
    required this.unit,
    required this.target,
    required this.passed,
  });

  final String name;
  final String value;
  final String unit;
  final String target;
  final bool passed;
}

/// Complete weaning readiness assessment.
class WeaningAssessment {
  const WeaningAssessment({
    required this.criteria,
    required this.passedCount,
    required this.totalCount,
    required this.readyToWean,
    required this.rsbi,
  });

  factory WeaningAssessment.initial() => const WeaningAssessment(
        criteria: [],
        passedCount: 0,
        totalCount: 0,
        readyToWean: false,
        rsbi: 0,
      );

  final List<WeaningCriterion> criteria;
  final int passedCount;
  final int totalCount;
  final bool readyToWean;
  final double rsbi;
}
