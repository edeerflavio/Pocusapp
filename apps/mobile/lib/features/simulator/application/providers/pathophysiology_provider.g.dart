// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pathophysiology_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activePathophysiologyHash() =>
    r'f0682ecb13009b7b30c1fd732ea42844ee5178f6';

/// Currently active pathophysiology events.
///
/// Used by [SimulationNotifier] in the game loop to decide which
/// modifiers to apply. Returns an empty list when no events are active.
///
/// Copied from [activePathophysiology].
@ProviderFor(activePathophysiology)
final activePathophysiologyProvider =
    Provider<List<PathophysiologyEvent>>.internal(
  activePathophysiology,
  name: r'activePathophysiologyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activePathophysiologyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActivePathophysiologyRef = ProviderRef<List<PathophysiologyEvent>>;
String _$hasActivePathophysiologyHash() =>
    r'a05b01ead1f8d38a59d4db62e4c18d0ea9c7de42';

/// Whether any pathophysiology event is currently active.
///
/// Used by the UI to show/hide warning indicators (e.g. red badge
/// on the Scenarios tab).
///
/// Copied from [hasActivePathophysiology].
@ProviderFor(hasActivePathophysiology)
final hasActivePathophysiologyProvider = Provider<bool>.internal(
  hasActivePathophysiology,
  name: r'hasActivePathophysiologyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasActivePathophysiologyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasActivePathophysiologyRef = ProviderRef<bool>;
String _$pathophysiologyNotifierHash() =>
    r'8dc9afa8bfd863dd0f9041a717d3354de1f3f457';

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
final pathophysiologyNotifierProvider =
    NotifierProvider<PathophysiologyNotifier, PathophysiologyState>.internal(
  PathophysiologyNotifier.new,
  name: r'pathophysiologyNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pathophysiologyNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PathophysiologyNotifier = Notifier<PathophysiologyState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
