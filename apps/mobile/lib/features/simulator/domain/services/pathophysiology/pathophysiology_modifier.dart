import '../../entities/pathophysiology/pathophysiology_entities.dart';
import '../../entities/ventilator_entities.dart';
import '../ventilator_engine.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PathophysiologyModifier — interface for all pathophysiology modifiers
// ═══════════════════════════════════════════════════════════════════════════

/// Interface that every pathophysiological modifier must implement.
///
/// Follows the **Chain of Responsibility** pattern: each modifier receives
/// the sample produced by the base engine (or the previous modifier in the
/// chain) and returns a potentially altered sample.
///
/// ## Design principle
///
/// The base [VentilatorEngine] computes a "perfect" single-compartment RC
/// lung. Modifiers *perturb* that result to simulate real-world pathologies
/// (secretion, pneumothorax, auto-PEEP, etc.). Multiple modifiers can be
/// active simultaneously — for example auto-PEEP + secretion — producing
/// complex, realistic clinical scenarios.
///
/// ## Two-phase pipeline
///
/// 1. **[modifyParams]** — runs *before* the engine, altering the
///    mechanical parameters the engine sees (e.g. pneumothorax lowers
///    compliance).  If any modifier changes params, the registry re-runs
///    the engine with the modified parameters.
/// 2. **[modifySample]** — runs *after* the engine, distorting the
///    resulting waveform (e.g. double-trigger injects a second breath,
///    circuit leak reduces exhaled volume).
///
/// **100 % pure Dart** — no Flutter, no Riverpod.
abstract class PathophysiologyModifier {
  /// The pathophysiology type this modifier handles.
  PathophysiologyType get type;

  /// Alters ventilator/lung parameters before the engine computes
  /// the breath sample.
  ///
  /// Called once per engine tick for every active modifier.
  /// Return [original] unmodified if this modifier does not need to
  /// change pre-engine parameters.
  VentParams modifyParams(
    VentParams original,
    PathophysiologyEvent event,
    double simTime,
  );

  /// Alters the breath sample after the engine has computed it.
  ///
  /// Called once per engine tick for every active modifier.
  /// Return [original] unmodified if this modifier only works in the
  /// pre-engine phase.
  BreathSample modifySample(
    BreathSample original,
    VentParams params,
    PathophysiologyEvent event,
    double simTime,
  );

  /// Resets any internal mutable state this modifier may accumulate
  /// across ticks (e.g. trapped volume, stochastic timers).
  ///
  /// Called when the simulation is reset or the event is deactivated.
  void reset();
}

// ═══════════════════════════════════════════════════════════════════════════
// PathophysiologyRegistry — applies all active modifiers in order
// ═══════════════════════════════════════════════════════════════════════════

/// Central registry that maps each [PathophysiologyType] to its concrete
/// [PathophysiologyModifier] and orchestrates the two-phase pipeline.
///
/// The [SimulationNotifier] calls [apply] on every engine tick, passing
/// the active events from [PathophysiologyState]. The registry:
///
/// 1. Runs [modifyParams] for each active event. If any modifier changed
///    the params, re-runs [VentilatorEngine.simulate] with the modified
///    parameters.
/// 2. Runs [modifySample] for each active event on the (possibly
///    re-computed) sample.
///
/// This keeps the engine untouched — pathophysiology is purely additive.
class PathophysiologyRegistry {
  PathophysiologyRegistry._();

  /// Registered modifier instances, keyed by event type.
  ///
  /// Populated lazily via [register]. Concrete modifiers are registered
  /// from outside this file to avoid circular dependencies and to keep
  /// the interface decoupled from the implementations.
  static final Map<PathophysiologyType, PathophysiologyModifier> _modifiers =
      {};

  /// Registers a concrete modifier for a given event type.
  ///
  /// Call this once per modifier at app startup or when the simulator
  /// module is first loaded.
  static void register(PathophysiologyModifier modifier) {
    _modifiers[modifier.type] = modifier;
  }

  /// Whether a modifier is registered for [type].
  static bool hasModifier(PathophysiologyType type) =>
      _modifiers.containsKey(type);

  /// Applies all active modifiers through the two-phase pipeline.
  ///
  /// Returns a record with the (possibly modified) params and sample.
  ///
  /// **Phase 1** — `modifyParams`: each active event's modifier may
  /// alter compliance, resistance, PEEP, etc. If any change occurred,
  /// the engine is re-run with the modified params.
  ///
  /// **Phase 2** — `modifySample`: each active event's modifier may
  /// alter pressure, flow, volume, or phase on the computed sample.
  static ({VentParams params, BreathSample sample}) apply({
    required VentParams originalParams,
    required BreathSample originalSample,
    required List<PathophysiologyEvent> activeEvents,
    required double simTime,
  }) {
    // ── Phase 1: modify params ──────────────────────────────────────────
    var params = originalParams;
    for (final event in activeEvents) {
      final mod = _modifiers[event.type];
      if (mod != null) {
        params = mod.modifyParams(params, event, simTime);
      }
    }

    // If any modifier changed the params, re-run the engine.
    var sample = originalSample;
    if (!identical(params, originalParams)) {
      sample = VentilatorEngine.simulate(params, simTime);
    }

    // ── Phase 2: modify sample ──────────────────────────────────────────
    for (final event in activeEvents) {
      final mod = _modifiers[event.type];
      if (mod != null) {
        sample = mod.modifySample(sample, params, event, simTime);
      }
    }

    return (params: params, sample: sample);
  }

  /// Resets all registered modifiers' internal state.
  static void resetAll() {
    for (final mod in _modifiers.values) {
      mod.reset();
    }
  }

  /// Resets only the modifier for [type].
  static void resetModifier(PathophysiologyType type) {
    _modifiers[type]?.reset();
  }
}
