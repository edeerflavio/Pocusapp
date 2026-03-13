/// Mechanical Ventilation Simulator module.
///
/// Provides a real-time ventilator simulation with VCV, PCV, and PSV modes,
/// ABG analysis, and an ICU-monitor-style presentation layer.
library simulator;

// ── Domain: Entities ─────────────────────────────────────────────────────────
export 'domain/entities/ventilator_entities.dart';

// ── Domain: Enums ────────────────────────────────────────────────────────────
export 'domain/enums/ventilation_enums.dart';

// ── Domain: Services ─────────────────────────────────────────────────────────
export 'domain/services/ventilator_engine.dart';
export 'domain/services/cycle_tracker.dart';
export 'domain/services/abg_analyzer.dart';

// ── Data: Presets ────────────────────────────────────────────────────────────
export 'data/presets/clinical_presets.dart';

// ── Application: Providers ───────────────────────────────────────────────────
export 'application/providers/patient_provider.dart';
export 'application/providers/ventilator_params_provider.dart';
export 'application/providers/simulation_provider.dart';
export 'application/providers/abg_provider.dart';
export 'application/providers/blood_gas_lab_provider.dart';

// ── Domain: Services (Blood Gas) ──────────────────────────────────────────
export 'domain/services/blood_gas_engine.dart';

// ── Presentation: Screens ────────────────────────────────────────────────────
export 'presentation/screens/simulator_screen.dart';

// ── Presentation: Widgets ────────────────────────────────────────────────────
export 'presentation/widgets/waveform_widget.dart';
export 'presentation/widgets/waveforms_column.dart';
export 'presentation/widgets/left_panel.dart';
export 'presentation/widgets/right_panel.dart';

// ── Presentation: Painters ───────────────────────────────────────────────────
export 'presentation/painters/waveform_painter.dart';
export 'presentation/widgets/ventilator_monitor_painter.dart';
export 'presentation/widgets/ventilator_control_panel.dart';
export 'presentation/widgets/blood_gas_panel.dart';
