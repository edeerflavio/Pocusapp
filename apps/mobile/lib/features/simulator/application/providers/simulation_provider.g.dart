// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simulation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cycleMetricsHash() => r'81ba3339f60fe095fb565e4a15542d482342f747';

/// Latest per-breath clinical metrics (PIP, PEEP, Vte, measured RR).
///
/// Derived from [simulationNotifierProvider]. Recalculates every time
/// the simulation emits a new state (i.e. ~20 fps, but CycleMetrics
/// only actually changes once per breath cycle).
///
/// Copied from [cycleMetrics].
@ProviderFor(cycleMetrics)
final cycleMetricsProvider = AutoDisposeProvider<CycleMetrics>.internal(
  cycleMetrics,
  name: r'cycleMetricsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cycleMetricsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CycleMetricsRef = AutoDisposeProviderRef<CycleMetrics>;
String _$simulationNotifierHash() =>
    r'45a811b2ad4e29da9fbd3f8204e4e02bef5af675';

/// See also [SimulationNotifier].
@ProviderFor(SimulationNotifier)
final simulationNotifierProvider =
    AutoDisposeNotifierProvider<SimulationNotifier, SimulationState>.internal(
  SimulationNotifier.new,
  name: r'simulationNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$simulationNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SimulationNotifier = AutoDisposeNotifier<SimulationState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
