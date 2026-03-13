/// Enumerations and constants for the mechanical ventilation simulator.
///
/// These types form the shared vocabulary between the domain engine,
/// the application layer (providers), and the presentation layer (UI).

// ---------------------------------------------------------------------------
// VentMode — ventilation operating mode
// ---------------------------------------------------------------------------

/// The three standard modes of invasive mechanical ventilation.
///
/// Each mode differs in which variable the operator controls (independent)
/// and which the machine adjusts (dependent):
///
/// | Mode | Operator sets        | Machine adjusts |
/// |------|----------------------|-----------------|
/// | VCV  | Vt + flow            | Airway pressure |
/// | PCV  | Driving pressure     | Tidal volume    |
/// | PSV  | Pressure support     | Vt (+ patient)  |
enum VentMode {
  /// Volume-Controlled Ventilation — the operator sets the tidal volume
  /// and inspiratory flow rate. Airway pressure is the dependent variable
  /// and rises with worsening compliance or resistance.
  vcv,

  /// Pressure-Controlled Ventilation — the operator sets a driving
  /// pressure above PEEP. The delivered tidal volume depends on lung
  /// compliance and the inspiratory time allowed.
  pcv,

  /// Pressure-Support Ventilation — patient-triggered, pressure-assisted
  /// breaths. The machine provides a set pressure support; the tidal
  /// volume depends on the patient's own effort and lung mechanics.
  /// Inspiration is terminated by flow cycling (typically at 25% of peak).
  psv,
}

/// Convenience accessors for display labels.
extension VentModeLabels on VentMode {
  /// Full Portuguese label for UI display.
  /// - vcv → 'Volume Controlado'
  /// - pcv → 'Pressão Controlada'
  /// - psv → 'Pressão de Suporte'
  String get label => switch (this) {
        VentMode.vcv => 'Volume Controlado',
        VentMode.pcv => 'Pressão Controlada',
        VentMode.psv => 'Pressão de Suporte',
      };

  /// Abbreviated label used in compact UI elements (chips, badges).
  String get shortLabel => switch (this) {
        VentMode.vcv => 'VCV',
        VentMode.pcv => 'PCV',
        VentMode.psv => 'PSV',
      };
}

// ---------------------------------------------------------------------------
// BreathPhase — current phase within a respiratory cycle
// ---------------------------------------------------------------------------

/// The two main phases of a single breath.
///
/// In a complete cycle:
/// 1. **Inspiration** — gas flows into the lungs (positive flow). In VCV
///    this includes an optional inspiratory pause (zero flow, sustained
///    pressure) used to measure plateau pressure.
/// 2. **Expiration** — passive recoil drives gas out (negative flow).
///    The lung empties exponentially with time constant τ = R × C.
enum BreathPhase {
  /// Gas entering the lungs. Duration determined by I:E ratio (VCV/PCV)
  /// or flow cycling threshold (PSV).
  inspiration,

  /// Passive exhalation. Duration = total cycle time − inspiratory time.
  /// If too short relative to τ, incomplete emptying causes auto-PEEP
  /// (intrinsic PEEP / air trapping).
  expiration,
}

// ---------------------------------------------------------------------------
// AlertLevel — clinical safety feedback
// ---------------------------------------------------------------------------

/// Severity levels for physiological alerts displayed to the learner.
///
/// Mapped to colour coding in the UI:
/// - [ok]      → green  — parameter within safe range
/// - [info]    → blue   — informational, no action needed
/// - [warning] → amber  — approaching unsafe territory
/// - [danger]  → red    — potentially harmful setting (e.g. Pplat > 30)
enum AlertLevel {
  /// All values within safe physiological range.
  ok,

  /// Informational note (e.g. "FiO₂ > 60% — considere desmame").
  info,

  /// Approaching a clinical limit (e.g. Pplat 28–30 cmH₂O).
  warning,

  /// Exceeding a recognised safety threshold (e.g. Pplat > 30 cmH₂O,
  /// driving pressure > 15 cmH₂O in ARDS, auto-PEEP > 5 cmH₂O).
  danger,
}

// ---------------------------------------------------------------------------
// Sex — biological sex for predicted body weight calculation
// ---------------------------------------------------------------------------

/// Biological sex used to compute Predicted Body Weight (PBW), which
/// determines the protective tidal volume target (6–8 mL/kg PBW).
///
/// ARDSnet formula:
/// - Male:   PBW = 50 + 0.91 × (height_cm − 152.4)
/// - Female: PBW = 45.5 + 0.91 × (height_cm − 152.4)
enum Sex {
  /// Male — baseline PBW = 50 kg at 152.4 cm.
  male,

  /// Female — baseline PBW = 45.5 kg at 152.4 cm.
  female,
}

// ---------------------------------------------------------------------------
// ClinicalPresetType — predefined lung pathology scenarios
// ---------------------------------------------------------------------------

/// Quick-select presets that configure compliance, resistance, and
/// ventilator settings to simulate common clinical scenarios.
///
/// Each preset teaches the learner how lung mechanics affect waveforms
/// and how to adjust the ventilator in response.
enum ClinicalPresetType {
  /// Healthy adult lungs.
  /// C ≈ 50 mL/cmH₂O, R ≈ 5 cmH₂O·s/L.
  normal,

  /// Síndrome do Desconforto Respiratório Agudo (ARDS/SDRA).
  /// Very low compliance (15–25 mL/cmH₂O), moderate resistance.
  /// Requires lung-protective ventilation: low Vt, high PEEP, high FiO₂.
  sdra,

  /// Asthma exacerbation — severe bronchospasm.
  /// Normal-to-high compliance, very high resistance (15–25 cmH₂O·s/L).
  /// Risk of dynamic hyperinflation and auto-PEEP.
  asma,

  /// Chronic Obstructive Pulmonary Disease (DPOC/COPD).
  /// High compliance (70–100 mL/cmH₂O, loss of elastic recoil),
  /// high resistance (15–20 cmH₂O·s/L).
  /// Long τ → requires prolonged expiratory time to avoid air trapping.
  dpoc,
}

// ---------------------------------------------------------------------------
// EngineConstants — fixed simulation parameters
// ---------------------------------------------------------------------------

/// Global constants for the ventilator simulation engine.
///
/// These values are tuned for a balance between physiological accuracy
/// and smooth real-time rendering on mobile devices.
abstract final class EngineConstants {
  /// Fixed simulation timestep in seconds (250 Hz).
  ///
  /// At 250 Hz, each step is 4 ms — sufficient to capture the fastest
  /// physiological transients (rise time ≈ 50–150 ms) while keeping
  /// computational cost low enough for 60 fps rendering.
  static const double dt = 0.004;

  /// Number of waveform samples retained in the rolling display buffer.
  ///
  /// At 250 Hz with a typical RR of 12–20 /min (cycle time 3–5 s),
  /// 1500 samples covers approximately 6 seconds — enough to display
  /// 2–3 complete breath cycles on screen at once.
  static const int bufferSize = 1500;

  /// Maximum number of recent breath cycles kept for derived metrics.
  ///
  /// Used to calculate rolling averages (e.g. measured RR from cycle
  /// timestamps, trend in peak pressure, compliance tracking).
  /// Eight cycles provides a clinically meaningful window (~30–60 s)
  /// without excessive memory use.
  static const int maxBreathHistory = 8;
}
