// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pocus_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pocusRepositoryHash() => r'b2ea40536f1cea3a104ab7f80ce4c775bbc2e77c';

/// See also [pocusRepository].
@ProviderFor(pocusRepository)
final pocusRepositoryProvider = Provider<PocusRepository>.internal(
  pocusRepository,
  name: r'pocusRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pocusRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PocusRepositoryRef = ProviderRef<PocusRepository>;
String _$watchPocusItemsHash() => r'a608ef9868a6652904030f5fd6a257c0735854fd';

/// See also [watchPocusItems].
@ProviderFor(watchPocusItems)
final watchPocusItemsProvider =
    AutoDisposeStreamProvider<List<PocusItem>>.internal(
  watchPocusItems,
  name: r'watchPocusItemsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$watchPocusItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WatchPocusItemsRef = AutoDisposeStreamProviderRef<List<PocusItem>>;
String _$watchMediaAssetsHash() => r'd2f47756243bdc1f0db432aaafcb0c9b828e5b31';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [watchMediaAssets].
@ProviderFor(watchMediaAssets)
const watchMediaAssetsProvider = WatchMediaAssetsFamily();

/// See also [watchMediaAssets].
class WatchMediaAssetsFamily extends Family<AsyncValue<List<MediaAsset>>> {
  /// See also [watchMediaAssets].
  const WatchMediaAssetsFamily();

  /// See also [watchMediaAssets].
  WatchMediaAssetsProvider call(
    String pocusItemId,
  ) {
    return WatchMediaAssetsProvider(
      pocusItemId,
    );
  }

  @override
  WatchMediaAssetsProvider getProviderOverride(
    covariant WatchMediaAssetsProvider provider,
  ) {
    return call(
      provider.pocusItemId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'watchMediaAssetsProvider';
}

/// See also [watchMediaAssets].
class WatchMediaAssetsProvider
    extends AutoDisposeStreamProvider<List<MediaAsset>> {
  /// See also [watchMediaAssets].
  WatchMediaAssetsProvider(
    String pocusItemId,
  ) : this._internal(
          (ref) => watchMediaAssets(
            ref as WatchMediaAssetsRef,
            pocusItemId,
          ),
          from: watchMediaAssetsProvider,
          name: r'watchMediaAssetsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$watchMediaAssetsHash,
          dependencies: WatchMediaAssetsFamily._dependencies,
          allTransitiveDependencies:
              WatchMediaAssetsFamily._allTransitiveDependencies,
          pocusItemId: pocusItemId,
        );

  WatchMediaAssetsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.pocusItemId,
  }) : super.internal();

  final String pocusItemId;

  @override
  Override overrideWith(
    Stream<List<MediaAsset>> Function(WatchMediaAssetsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchMediaAssetsProvider._internal(
        (ref) => create(ref as WatchMediaAssetsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        pocusItemId: pocusItemId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<MediaAsset>> createElement() {
    return _WatchMediaAssetsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchMediaAssetsProvider &&
        other.pocusItemId == pocusItemId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, pocusItemId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WatchMediaAssetsRef on AutoDisposeStreamProviderRef<List<MediaAsset>> {
  /// The parameter `pocusItemId` of this provider.
  String get pocusItemId;
}

class _WatchMediaAssetsProviderElement
    extends AutoDisposeStreamProviderElement<List<MediaAsset>>
    with WatchMediaAssetsRef {
  _WatchMediaAssetsProviderElement(super.provider);

  @override
  String get pocusItemId => (origin as WatchMediaAssetsProvider).pocusItemId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
