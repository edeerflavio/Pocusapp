// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pathophysiology_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activePathophysiologyHash() =>
    r'29512680db5e03146d8771683c2b8af4c09cc8f7';

/// Currently active pathophysiology events.
///
/// Used by [SimulationNotifier] in the game loop to decide which
/// modifiers to apply. Returns an empty list when no events are active.
///
/// Copied from [activePathophysiology].
@ProviderFor(activePathophysiology)
final activePathophysiologyProvider =
    AutoDisposeProvider<List<PathophysiologyEvent>>.internal(
  activePathophysiology,
  name: r'activePathophysiologyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activePathophysiologyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActivePathophysiologyRef
    = AutoDisposeProviderRef<List<PathophysiologyEvent>>;
String _$hasActivePathophysiologyHash() =>
    r'f36ff4bd18fe28508c66e39f09eabb3b5b8f1e97';

/// Whether any pathophysiology event is currently active.
///
/// Used by the UI to show/hide warning indicators (e.g. red badge
/// on the Scenarios tab).
///
/// Copied from [hasActivePathophysiology].
@ProviderFor(hasActivePathophysiology)
final hasActivePathophysiologyProvider = AutoDisposeProvider<bool>.internal(
  hasActivePathophysiology,
  name: r'hasActivePathophysiologyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasActivePathophysiologyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasActivePathophysiologyRef = AutoDisposeProviderRef<bool>;
String _$pathophysiologyNotifierHash() =>
    r'ea1403e3744ded109c776eed2e517197d1e46da3';

/// Manages the set of pathophysiological events that can be overlaid on
/// the base ventilator simulation.
///
/// Each event can be independently toggled, and its severity/intensity
/// adjusted. The [SimulationNotifier] reads the active events via
/// [activePathophysiologyProvider] and applies the corresponding
/// modifiers through [PathophysiologyRegistry].
///
/// Copied from [PathophysiologyNotifier].
@ProviderFor(PathophysiologyNotifier)
final pathophysiologyNotifierProvider = AutoDisposeNotifierProvider<
    PathophysiologyNotifier, PathophysiologyState>.internal(
  PathophysiologyNotifier.new,
  name: r'pathophysiologyNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pathophysiologyNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PathophysiologyNotifier = AutoDisposeNotifier<PathophysiologyState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
