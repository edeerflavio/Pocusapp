// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blood_gas_lab_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$liveAbgPreviewHash() => r'764498cbe276c327b22e78726e730af4ccf7732b';

/// Live (unfrozen) ABG preview — computed every frame for the real-time
/// display. Shows what the next gasometry would return if requested now.
///
/// Copied from [liveAbgPreview].
@ProviderFor(liveAbgPreview)
final liveAbgPreviewProvider = AutoDisposeProvider<DynamicAbgResult>.internal(
  liveAbgPreview,
  name: r'liveAbgPreviewProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$liveAbgPreviewHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LiveAbgPreviewRef = AutoDisposeProviderRef<DynamicAbgResult>;
String _$weaningAssessmentHash() => r'9f6fa3c3c72c4d4466bd919fcaa2b4cd72f17b2d';

/// Weaning assessment — only meaningful in PSV mode.
///
/// Watches simulation metrics + live ABG to evaluate readiness.
///
/// Copied from [weaningAssessment].
@ProviderFor(weaningAssessment)
final weaningAssessmentProvider =
    AutoDisposeProvider<WeaningAssessment>.internal(
  weaningAssessment,
  name: r'weaningAssessmentProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$weaningAssessmentHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WeaningAssessmentRef = AutoDisposeProviderRef<WeaningAssessment>;
String _$bloodGasLabNotifierHash() =>
    r'b7db86fc9dde995c3d666bb74074fc507161fde1';

/// See also [BloodGasLabNotifier].
@ProviderFor(BloodGasLabNotifier)
final bloodGasLabNotifierProvider =
    NotifierProvider<BloodGasLabNotifier, BloodGasLabState>.internal(
  BloodGasLabNotifier.new,
  name: r'bloodGasLabNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bloodGasLabNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BloodGasLabNotifier = Notifier<BloodGasLabState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
