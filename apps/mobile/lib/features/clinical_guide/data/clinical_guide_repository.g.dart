// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinical_guide_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clinicalGuideRepositoryHash() =>
    r'270f40fedb6ee8751d822b2f5ba9c3df138303ea';

/// See also [clinicalGuideRepository].
@ProviderFor(clinicalGuideRepository)
final clinicalGuideRepositoryProvider =
    AutoDisposeProvider<ClinicalGuideRepository>.internal(
  clinicalGuideRepository,
  name: r'clinicalGuideRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$clinicalGuideRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ClinicalGuideRepositoryRef
    = AutoDisposeProviderRef<ClinicalGuideRepository>;
String _$watchDiseasesHash() => r'ef4d09ff05e3f67c1fb8513d7512b4d4d1e46b91';

/// See also [watchDiseases].
@ProviderFor(watchDiseases)
final watchDiseasesProvider = AutoDisposeStreamProvider<List<Disease>>.internal(
  watchDiseases,
  name: r'watchDiseasesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$watchDiseasesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WatchDiseasesRef = AutoDisposeStreamProviderRef<List<Disease>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
