// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ventilator_params_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$drivingPressureHash() => r'75aa0a591345e1ece5bbab15d9e320c6a00aea69';

/// Driving Pressure (cmH₂O) = Vte / Compliance.
///
/// The strongest independent predictor of mortality in ARDS (Amato 2015).
/// Target ≤ 15 cmH₂O. Uses measured Vte when available, otherwise set Vt.
///
/// Copied from [drivingPressure].
@ProviderFor(drivingPressure)
final drivingPressureProvider = AutoDisposeProvider<double>.internal(
  drivingPressure,
  name: r'drivingPressureProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$drivingPressureHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DrivingPressureRef = AutoDisposeProviderRef<double>;
String _$plateauPressureHash() => r'1844b7728039453a5926cf0d1efc3891a6fcd086';

/// Plateau Pressure (cmH₂O) = PEEP + Driving Pressure.
///
/// Reflects alveolar distending pressure. Target ≤ 30 cmH₂O to prevent
/// ventilator-induced lung injury (VILI / barotrauma).
///
/// Copied from [plateauPressure].
@ProviderFor(plateauPressure)
final plateauPressureProvider = AutoDisposeProvider<double>.internal(
  plateauPressure,
  name: r'plateauPressureProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$plateauPressureHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PlateauPressureRef = AutoDisposeProviderRef<double>;
String _$vtPerKgHash() => r'73b6a13d539fb485b0ff6f2560079891b24814fb';

/// Tidal Volume per kg of Ideal Body Weight (mL/kg IBW).
///
/// Lung-protective range: 6–8 mL/kg IBW (ARDSNet). Uses measured Vte
/// when available, otherwise the set Vt.
///
/// Copied from [vtPerKg].
@ProviderFor(vtPerKg)
final vtPerKgProvider = AutoDisposeProvider<double>.internal(
  vtPerKg,
  name: r'vtPerKgProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$vtPerKgHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VtPerKgRef = AutoDisposeProviderRef<double>;
String _$mechanicalPowerHash() => r'703fd39119455ebf9777e3230309e491de9cba68';

/// Mechanical Power (J/min) — simplified Gattinoni formula.
///
/// MP = 0.098 × RR × (Vt/1000) × (PIP − DP/2)
///
/// Quantifies the total energy delivered to the respiratory system per
/// minute. Threshold ≥ 17 J/min associated with increased VILI risk.
/// Uses measured PIP when available, otherwise the set PIP from VentParams.
///
/// Copied from [mechanicalPower].
@ProviderFor(mechanicalPower)
final mechanicalPowerProvider = AutoDisposeProvider<double>.internal(
  mechanicalPower,
  name: r'mechanicalPowerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mechanicalPowerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MechanicalPowerRef = AutoDisposeProviderRef<double>;
String _$ventParamsNotifierHash() =>
    r'd1587b71835c44d11ad7f25a60f95cf8ece9ccb5';

/// See also [VentParamsNotifier].
@ProviderFor(VentParamsNotifier)
final ventParamsNotifierProvider =
    NotifierProvider<VentParamsNotifier, VentParams>.internal(
  VentParamsNotifier.new,
  name: r'ventParamsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ventParamsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VentParamsNotifier = Notifier<VentParams>;
String _$activePresetHash() => r'db09f2cbef0c72797ecbd836e6ac63f473816f64';

/// See also [ActivePreset].
@ProviderFor(ActivePreset)
final activePresetProvider =
    NotifierProvider<ActivePreset, ClinicalPresetType?>.internal(
  ActivePreset.new,
  name: r'activePresetProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$activePresetHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActivePreset = Notifier<ClinicalPresetType?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
