// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MediaAsset {
  String get id => throw _privateConstructorUsedError;
  String get ownerType => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError; // 'image' | 'video'
  String get path =>
      throw _privateConstructorUsedError; // Supabase Storage path
  String? get thumbPath => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MediaAssetCopyWith<MediaAsset> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaAssetCopyWith<$Res> {
  factory $MediaAssetCopyWith(
          MediaAsset value, $Res Function(MediaAsset) then) =
      _$MediaAssetCopyWithImpl<$Res, MediaAsset>;
  @useResult
  $Res call(
      {String id,
      String ownerType,
      String ownerId,
      String kind,
      String path,
      String? thumbPath});
}

/// @nodoc
class _$MediaAssetCopyWithImpl<$Res, $Val extends MediaAsset>
    implements $MediaAssetCopyWith<$Res> {
  _$MediaAssetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerType = null,
    Object? ownerId = null,
    Object? kind = null,
    Object? path = null,
    Object? thumbPath = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerType: null == ownerType
          ? _value.ownerType
          : ownerType // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      thumbPath: freezed == thumbPath
          ? _value.thumbPath
          : thumbPath // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MediaAssetImplCopyWith<$Res>
    implements $MediaAssetCopyWith<$Res> {
  factory _$$MediaAssetImplCopyWith(
          _$MediaAssetImpl value, $Res Function(_$MediaAssetImpl) then) =
      __$$MediaAssetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String ownerType,
      String ownerId,
      String kind,
      String path,
      String? thumbPath});
}

/// @nodoc
class __$$MediaAssetImplCopyWithImpl<$Res>
    extends _$MediaAssetCopyWithImpl<$Res, _$MediaAssetImpl>
    implements _$$MediaAssetImplCopyWith<$Res> {
  __$$MediaAssetImplCopyWithImpl(
      _$MediaAssetImpl _value, $Res Function(_$MediaAssetImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerType = null,
    Object? ownerId = null,
    Object? kind = null,
    Object? path = null,
    Object? thumbPath = freezed,
  }) {
    return _then(_$MediaAssetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerType: null == ownerType
          ? _value.ownerType
          : ownerType // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      thumbPath: freezed == thumbPath
          ? _value.thumbPath
          : thumbPath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MediaAssetImpl implements _MediaAsset {
  const _$MediaAssetImpl(
      {required this.id,
      required this.ownerType,
      required this.ownerId,
      required this.kind,
      required this.path,
      this.thumbPath});

  @override
  final String id;
  @override
  final String ownerType;
  @override
  final String ownerId;
  @override
  final String kind;
// 'image' | 'video'
  @override
  final String path;
// Supabase Storage path
  @override
  final String? thumbPath;

  @override
  String toString() {
    return 'MediaAsset(id: $id, ownerType: $ownerType, ownerId: $ownerId, kind: $kind, path: $path, thumbPath: $thumbPath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaAssetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerType, ownerType) ||
                other.ownerType == ownerType) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.thumbPath, thumbPath) ||
                other.thumbPath == thumbPath));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, ownerType, ownerId, kind, path, thumbPath);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaAssetImplCopyWith<_$MediaAssetImpl> get copyWith =>
      __$$MediaAssetImplCopyWithImpl<_$MediaAssetImpl>(this, _$identity);
}

abstract class _MediaAsset implements MediaAsset {
  const factory _MediaAsset(
      {required final String id,
      required final String ownerType,
      required final String ownerId,
      required final String kind,
      required final String path,
      final String? thumbPath}) = _$MediaAssetImpl;

  @override
  String get id;
  @override
  String get ownerType;
  @override
  String get ownerId;
  @override
  String get kind;
  @override // 'image' | 'video'
  String get path;
  @override // Supabase Storage path
  String? get thumbPath;
  @override
  @JsonKey(ignore: true)
  _$$MediaAssetImplCopyWith<_$MediaAssetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
