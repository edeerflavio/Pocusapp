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
    r'2f76c6a974b41d762cbd7833fb6e58c28b5e38ee';

/// See also [SimulationNotifier].
@ProviderFor(SimulationNotifier)
final simulationNotifierProvider =
    NotifierProvider<SimulationNotifier, SimulationState>.internal(
  SimulationNotifier.new,
  name: r'simulationNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$simulationNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SimulationNotifier = Notifier<SimulationState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
