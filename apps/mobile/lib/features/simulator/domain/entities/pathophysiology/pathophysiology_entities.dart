import 'package:meta/meta.dart' show immutable;

// ═══════════════════════════════════════════════════════════════════════════
// 1. PathophysiologyType — catalog of simulated clinical events
// ═══════════════════════════════════════════════════════════════════════════

/// Enumerates the pathophysiological events the simulator can overlay
/// on top of the base RC ventilator model.
///
/// Each type maps to a concrete [PathophysiologyModifier] that alters
/// compliance, resistance, leak fraction, or breath timing without
/// touching the core engine.
enum PathophysiologyType {
  /// Dynamic hyperinflation caused by insufficient expiratory time.
  ///
  /// Common in obstructive diseases (COPD, asthma) and when RR is too
  /// high or I:E ratio is inverted. The modifier adds residual volume
  /// that shifts the baseline pressure above set PEEP.
  autoPeep,

  /// The patient's inspiratory effort triggers a second ventilator
  /// cycle before the current expiration has completed.
  ///
  /// Clinically associated with high drive, short cycling, or
  /// inappropriate trigger sensitivity. Produces a characteristic
  /// "stacked breath" pattern on the waveform.
  doubleTrigger,

  /// Mucus or blood accumulation inside the endotracheal tube or
  /// proximal airways.
  ///
  /// Increases airway resistance progressively. On the ventilator
  /// this manifests as rising PIP with stable plateau (VCV) or
  /// falling tidal volume (PCV/PSV).
  secretion,

  /// Partial or complete lung collapse from air in the pleural space.
  ///
  /// Causes an abrupt drop in compliance. Waveforms show a sudden
  /// rise in PIP (VCV) or fall in Vt (PCV), often with hemodynamic
  /// compromise (tachycardia, hypotension).
  pneumothorax,

  /// Acute bronchial smooth-muscle constriction.
  ///
  /// Dramatically increases expiratory resistance (more than
  /// inspiratory). Produces auto-PEEP, prolonged expiratory flow,
  /// and the classic "shark-fin" capnography pattern.
  bronchospasm,

  /// Gas leak in the ventilator circuit (cuff leak, circuit
  /// disconnect, or chest-tube bronchopleural fistula).
  ///
  /// Reduces the volume effectively delivered to the patient.
  /// VCV shows falling Vte with stable PIP; PCV shows stable
  /// pressure but reduced exhaled volume.
  circuitLeak,

  /// The endotracheal tube has migrated into the right mainstem
  /// bronchus, ventilating only the right lung.
  ///
  /// Effectively halves functional compliance and increases
  /// dead-space ventilation. PIP rises or Vt drops depending
  /// on mode; oxygenation deteriorates.
  rightMainstemIntubation,
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. PathophysiologySeverity — three-tier clinical grading
// ═══════════════════════════════════════════════════════════════════════════

/// Severity tier that scales the magnitude of each modifier's effect.
///
/// The numeric multiplier applied by each modifier typically follows:
/// - [mild] ≈ 25 % of maximal effect
/// - [moderate] ≈ 50 %
/// - [severe] ≈ 100 %
enum PathophysiologySeverity {
  /// Subtle changes — detectable on waveforms but not immediately
  /// alarming. Useful for teaching pattern recognition.
  mild,

  /// Clinically significant changes that require intervention.
  /// Default severity for new events.
  moderate,

  /// Life-threatening derangement demanding immediate action
  /// (e.g. tension pneumothorax, severe bronchospasm).
  severe,
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. PathophysiologyEvent — a single configurable clinical event
// ═══════════════════════════════════════════════════════════════════════════

/// Represents one pathophysiological event that can be toggled on/off
/// and tuned by the learner or instructor.
///
/// Events are pure data — they carry no simulation logic. The
/// corresponding [PathophysiologyModifier] reads the event's fields
/// to compute the parameter deltas applied each engine tick.
@immutable
class PathophysiologyEvent {
  const PathophysiologyEvent({
    required this.type,
    required this.active,
    required this.severity,
    required this.intensity,
    this.onsetTime,
    required this.continuous,
  });

  /// Factory for an inactive event at default settings.
  factory PathophysiologyEvent.initial(PathophysiologyType type) =>
      PathophysiologyEvent(
        type: type,
        active: false,
        severity: PathophysiologySeverity.moderate,
        intensity: 0.5,
        continuous: type != PathophysiologyType.doubleTrigger,
      );

  /// Which pathophysiological phenomenon this event represents.
  final PathophysiologyType type;

  /// Whether the event is currently affecting the simulation.
  ///
  /// Toggling this is the primary way the UI enables/disables an event
  /// without losing the user's severity and intensity settings.
  final bool active;

  /// Coarse severity tier that gates the effect magnitude.
  ///
  /// Clinically maps to how "sick" the virtual patient is:
  /// mild = early / compensated, severe = decompensated / emergent.
  final PathophysiologySeverity severity;

  /// Fine-grained intensity scalar in the range \[0.0, 1.0\].
  ///
  /// Allows continuous adjustment within the chosen severity tier.
  /// For example, [PathophysiologyType.secretion] at severity
  /// [PathophysiologySeverity.moderate] and intensity 0.8 produces
  /// a near-severe resistance increase.
  final double intensity;

  /// Simulation-clock time (seconds) at which the event was activated.
  ///
  /// Used by modifiers that ramp up gradually (e.g. pneumothorax
  /// tension build-up) rather than applying the full effect instantly.
  /// `null` when the event has never been activated.
  final double? onsetTime;

  /// Whether the event is continuous or episodic.
  ///
  /// Continuous events (e.g. pneumothorax, secretion) persist every
  /// breath cycle. Episodic events (e.g. double-trigger) fire
  /// stochastically based on intensity as a probability.
  final bool continuous;

  // ── Localised display helpers (PT-BR) ──────────────────────────────────

  /// Short human-readable label for the event type.
  String get label => switch (type) {
        PathophysiologyType.autoPeep => 'Auto-PEEP',
        PathophysiologyType.doubleTrigger => 'Duplo Disparo',
        PathophysiologyType.secretion => 'Secrecao no Tubo',
        PathophysiologyType.pneumothorax => 'Pneumotorax',
        PathophysiologyType.bronchospasm => 'Broncoespasmo Agudo',
        PathophysiologyType.circuitLeak => 'Vazamento no Circuito',
        PathophysiologyType.rightMainstemIntubation => 'Intubacao Seletiva',
      };

  /// One-line clinical explanation of the event's mechanism.
  String get description => switch (type) {
        PathophysiologyType.autoPeep =>
          'Hiperinsuflacao dinamica por tempo expiratorio insuficiente',
        PathophysiologyType.doubleTrigger =>
          'Esforco do paciente dispara segundo ciclo antes do fim da expiracao',
        PathophysiologyType.secretion =>
          'Acumulo de secrecao aumenta resistencia de via aerea',
        PathophysiologyType.pneumothorax =>
          'Colapso pulmonar com queda abrupta de complacencia',
        PathophysiologyType.bronchospasm =>
          'Constricao bronquica aguda com aumento subito de resistencia',
        PathophysiologyType.circuitLeak =>
          'Vazamento no circuito reduz volume entregue ao paciente',
        PathophysiologyType.rightMainstemIntubation =>
          'Tubo migrou para bronquio direito — ventilacao de 1 pulmao',
      };

  /// Visual indicator emoji for quick identification in the UI.
  String get emoji => switch (type) {
        PathophysiologyType.autoPeep => '\u{1F504}',
        PathophysiologyType.doubleTrigger => '\u{26A1}',
        PathophysiologyType.secretion => '\u{1F4A7}',
        PathophysiologyType.pneumothorax => '\u{1F4A5}',
        PathophysiologyType.bronchospasm => '\u{1FAC1}',
        PathophysiologyType.circuitLeak => '\u{1F573}',
        PathophysiologyType.rightMainstemIntubation => '\u{27A1}',
      };

  /// Creates a copy with the given fields replaced.
  PathophysiologyEvent copyWith({
    PathophysiologyType? type,
    bool? active,
    PathophysiologySeverity? severity,
    double? intensity,
    double? Function()? onsetTime,
    bool? continuous,
  }) =>
      PathophysiologyEvent(
        type: type ?? this.type,
        active: active ?? this.active,
        severity: severity ?? this.severity,
        intensity: intensity ?? this.intensity,
        onsetTime: onsetTime != null ? onsetTime() : this.onsetTime,
        continuous: continuous ?? this.continuous,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. PathophysiologyState — aggregate state of all events
// ═══════════════════════════════════════════════════════════════════════════

/// Holds the full set of pathophysiological events and provides
/// convenience accessors for active-event queries.
///
/// This is the state shape managed by `PathophysiologyNotifier` and
/// read by the `SimulationNotifier` to decide which modifiers to apply.
@immutable
class PathophysiologyState {
  const PathophysiologyState({required this.events});

  /// Creates the default state with all events inactive at moderate
  /// severity and 50 % intensity.
  factory PathophysiologyState.initial() => PathophysiologyState(
        events: PathophysiologyType.values
            .map(PathophysiologyEvent.initial)
            .toList(),
      );

  /// The complete list of events — one per [PathophysiologyType].
  ///
  /// Order matches [PathophysiologyType.values] so UI list-builders
  /// can iterate directly.
  final List<PathophysiologyEvent> events;

  /// Subset of events currently affecting the simulation.
  List<PathophysiologyEvent> get activeEvents =>
      events.where((e) => e.active).toList();

  /// Fast check used by the game loop to skip modifier application
  /// when no events are active.
  bool get hasActiveEvents => events.any((e) => e.active);

  /// Retrieves the event for a specific [PathophysiologyType].
  PathophysiologyEvent eventOf(PathophysiologyType type) =>
      events.firstWhere((e) => e.type == type);

  /// Returns a new state with the event at [index] replaced.
  PathophysiologyState replaceEvent(int index, PathophysiologyEvent event) {
    final updated = List<PathophysiologyEvent>.of(events);
    updated[index] = event;
    return PathophysiologyState(events: updated);
  }

  /// Returns a new state with the event matching [type] replaced.
  PathophysiologyState replaceEventByType(
    PathophysiologyType type,
    PathophysiologyEvent event,
  ) {
    final index = events.indexWhere((e) => e.type == type);
    if (index == -1) return this;
    return replaceEvent(index, event);
  }

  /// Creates a copy with the given fields replaced.
  PathophysiologyState copyWith({List<PathophysiologyEvent>? events}) =>
      PathophysiologyState(events: events ?? this.events);
}
