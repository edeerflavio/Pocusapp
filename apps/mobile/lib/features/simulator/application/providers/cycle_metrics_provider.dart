import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/ventilator_entities.dart';

part 'cycle_metrics_provider.g.dart';

// ---------------------------------------------------------------------------
// CycleMetricsNotifier — stores the latest per-breath metrics.
//
// Updated once per breath cycle by the simulation game loop when a new
// expiration begins (i.e. peak values from the completed inspiration are
// "frozen" and published here).
//
// Downstream derived providers (drivingPressure, vtPerKg, mechanicalPower)
// watch this and recompute automatically.
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class CycleMetricsNotifier extends _$CycleMetricsNotifier {
  @override
  CycleMetrics build() => CycleMetrics.initial();

  /// Called by the simulation loop at each breath boundary.
  void update(CycleMetrics metrics) => state = metrics;

  /// Reset to zeroed state (e.g. when simulation stops).
  void reset() => state = CycleMetrics.initial();
}
