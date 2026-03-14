import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/pathophysiology/pathophysiology_entities.dart';
import '../../domain/services/pathophysiology/auto_peep_modifier.dart';
import '../../domain/services/pathophysiology/bronchospasm_modifier.dart';
import '../../domain/services/pathophysiology/circuit_leak_modifier.dart';
import '../../domain/services/pathophysiology/double_trigger_modifier.dart';
import '../../domain/services/pathophysiology/pathophysiology_modifier.dart';
import '../../domain/services/pathophysiology/pneumothorax_modifier.dart';
import '../../domain/services/pathophysiology/right_mainstem_modifier.dart';
import '../../domain/services/pathophysiology/secretion_modifier.dart';

part 'pathophysiology_provider.g.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PathophysiologyNotifier — manages active clinical scenarios
// ═══════════════════════════════════════════════════════════════════════════

/// Manages the set of pathophysiological events that can be overlaid on
/// the base ventilator simulation.
///
/// Each event can be independently toggled, and its severity/intensity
/// adjusted. The [SimulationNotifier] reads the active events via
/// [activePathophysiologyProvider] and applies the corresponding
/// modifiers through [PathophysiologyRegistry].
@Riverpod(keepAlive: true)
class PathophysiologyNotifier extends _$PathophysiologyNotifier {
  @override
  PathophysiologyState build() {
    // Register all concrete modifiers on first build.
    _ensureModifiersRegistered();
    return PathophysiologyState.initial();
  }

  /// Registers all modifier implementations in the registry.
  ///
  /// Called once; subsequent calls are no-ops because the registry
  /// is a static singleton.
  static bool _registered = false;
  static void _ensureModifiersRegistered() {
    if (_registered) return;
    _registered = true;
    PathophysiologyRegistry.register(AutoPeepModifier());
    PathophysiologyRegistry.register(DoubleTriggerModifier());
    PathophysiologyRegistry.register(SecretionModifier());
    PathophysiologyRegistry.register(PneumothoraxModifier());
    PathophysiologyRegistry.register(BronchospasmModifier());
    PathophysiologyRegistry.register(CircuitLeakModifier());
    PathophysiologyRegistry.register(RightMainstemModifier());
  }

  /// Toggles an event on or off.
  ///
  /// When activating, records [onsetTime] as the current wall-clock
  /// approximation. When deactivating, resets the corresponding
  /// modifier's internal state.
  void toggleEvent(PathophysiologyType type) {
    final current = state.eventOf(type);
    final nowActive = !current.active;

    if (nowActive) {
      // Activate — record onset.
      state = state.replaceEventByType(
        type,
        current.copyWith(
          active: true,
          onsetTime: () => DateTime.now().millisecondsSinceEpoch / 1000.0,
        ),
      );
    } else {
      // Deactivate — reset modifier state and clear onset.
      PathophysiologyRegistry.resetModifier(type);
      state = state.replaceEventByType(
        type,
        current.copyWith(active: false, onsetTime: () => null),
      );
    }
  }

  /// Updates the intensity (0.0–1.0) for an event.
  void setIntensity(PathophysiologyType type, double intensity) {
    final current = state.eventOf(type);
    state = state.replaceEventByType(
      type,
      current.copyWith(intensity: intensity.clamp(0.0, 1.0)),
    );
  }

  /// Updates the severity tier for an event.
  void setSeverity(PathophysiologyType type, PathophysiologySeverity severity) {
    final current = state.eventOf(type);
    state = state.replaceEventByType(
      type,
      current.copyWith(severity: severity),
    );
  }

  /// Deactivates all events and resets all modifier state.
  void clearAll() {
    PathophysiologyRegistry.resetAll();
    state = PathophysiologyState.initial();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Derived providers
// ═══════════════════════════════════════════════════════════════════════════

/// Currently active pathophysiology events.
///
/// Used by [SimulationNotifier] in the game loop to decide which
/// modifiers to apply. Returns an empty list when no events are active.
@Riverpod(keepAlive: true)
List<PathophysiologyEvent> activePathophysiology(
    ActivePathophysiologyRef ref) =>
    ref.watch(pathophysiologyNotifierProvider).activeEvents;

/// Whether any pathophysiology event is currently active.
///
/// Used by the UI to show/hide warning indicators (e.g. red badge
/// on the Scenarios tab).
@Riverpod(keepAlive: true)
bool hasActivePathophysiology(HasActivePathophysiologyRef ref) =>
    ref.watch(pathophysiologyNotifierProvider).hasActiveEvents;
