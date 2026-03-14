// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ibwHash() => r'358d338546118d348f372f5df873dae758931cad';

/// Ideal Body Weight (kg) — ARDSNet / Devine formula.
///
/// Copied from [ibw].
@ProviderFor(ibw)
final ibwProvider = AutoDisposeProvider<double>.internal(
  ibw,
  name: r'ibwProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$ibwHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IbwRef = AutoDisposeProviderRef<double>;
String _$bmiHash() => r'df54fd9cd04f0c333e23788d0055b912162b6187';

/// Body Mass Index (kg/m²).
///
/// Copied from [bmi].
@ProviderFor(bmi)
final bmiProvider = AutoDisposeProvider<double>.internal(
  bmi,
  name: r'bmiProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$bmiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BmiRef = AutoDisposeProviderRef<double>;
String _$idealVt6Hash() => r'07cb06cecb3de0d33bb76bcfe2cd6ec4faff4fab';

/// Lower bound of protective tidal volume: 6 mL/kg IBW (mL).
///
/// Copied from [idealVt6].
@ProviderFor(idealVt6)
final idealVt6Provider = AutoDisposeProvider<int>.internal(
  idealVt6,
  name: r'idealVt6Provider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$idealVt6Hash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IdealVt6Ref = AutoDisposeProviderRef<int>;
String _$idealVt8Hash() => r'fbdfa4172d5ea56f46acaf2405eb738c5c065a22';

/// Upper bound of protective tidal volume: 8 mL/kg IBW (mL).
///
/// Copied from [idealVt8].
@ProviderFor(idealVt8)
final idealVt8Provider = AutoDisposeProvider<int>.internal(
  idealVt8,
  name: r'idealVt8Provider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$idealVt8Hash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IdealVt8Ref = AutoDisposeProviderRef<int>;
String _$patientNotifierHash() => r'0f87013275ba4e52e5369cba6bc69171babaa538';

/// See also [PatientNotifier].
@ProviderFor(PatientNotifier)
final patientNotifierProvider =
    NotifierProvider<PatientNotifier, PatientData>.internal(
  PatientNotifier.new,
  name: r'patientNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$patientNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PatientNotifier = Notifier<PatientData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
