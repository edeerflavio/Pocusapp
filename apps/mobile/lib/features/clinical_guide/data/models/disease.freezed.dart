// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'disease.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Disease {
  String get id => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get titlePt => throw _privateConstructorUsedError;
  String get titleEs => throw _privateConstructorUsedError;
  String get bodyPt => throw _privateConstructorUsedError;
  String get bodyEs => throw _privateConstructorUsedError;
  bool get isPremium => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DiseaseCopyWith<Disease> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiseaseCopyWith<$Res> {
  factory $DiseaseCopyWith(Disease value, $Res Function(Disease) then) =
      _$DiseaseCopyWithImpl<$Res, Disease>;
  @useResult
  $Res call(
      {String id,
      String slug,
      String titlePt,
      String titleEs,
      String bodyPt,
      String bodyEs,
      bool isPremium,
      String status});
}

/// @nodoc
class _$DiseaseCopyWithImpl<$Res, $Val extends Disease>
    implements $DiseaseCopyWith<$Res> {
  _$DiseaseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? slug = null,
    Object? titlePt = null,
    Object? titleEs = null,
    Object? bodyPt = null,
    Object? bodyEs = null,
    Object? isPremium = null,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      titlePt: null == titlePt
          ? _value.titlePt
          : titlePt // ignore: cast_nullable_to_non_nullable
              as String,
      titleEs: null == titleEs
          ? _value.titleEs
          : titleEs // ignore: cast_nullable_to_non_nullable
              as String,
      bodyPt: null == bodyPt
          ? _value.bodyPt
          : bodyPt // ignore: cast_nullable_to_non_nullable
              as String,
      bodyEs: null == bodyEs
          ? _value.bodyEs
          : bodyEs // ignore: cast_nullable_to_non_nullable
              as String,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiseaseImplCopyWith<$Res> implements $DiseaseCopyWith<$Res> {
  factory _$$DiseaseImplCopyWith(
          _$DiseaseImpl value, $Res Function(_$DiseaseImpl) then) =
      __$$DiseaseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String slug,
      String titlePt,
      String titleEs,
      String bodyPt,
      String bodyEs,
      bool isPremium,
      String status});
}

/// @nodoc
class __$$DiseaseImplCopyWithImpl<$Res>
    extends _$DiseaseCopyWithImpl<$Res, _$DiseaseImpl>
    implements _$$DiseaseImplCopyWith<$Res> {
  __$$DiseaseImplCopyWithImpl(
      _$DiseaseImpl _value, $Res Function(_$DiseaseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? slug = null,
    Object? titlePt = null,
    Object? titleEs = null,
    Object? bodyPt = null,
    Object? bodyEs = null,
    Object? isPremium = null,
    Object? status = null,
  }) {
    return _then(_$DiseaseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      titlePt: null == titlePt
          ? _value.titlePt
          : titlePt // ignore: cast_nullable_to_non_nullable
              as String,
      titleEs: null == titleEs
          ? _value.titleEs
          : titleEs // ignore: cast_nullable_to_non_nullable
              as String,
      bodyPt: null == bodyPt
          ? _value.bodyPt
          : bodyPt // ignore: cast_nullable_to_non_nullable
              as String,
      bodyEs: null == bodyEs
          ? _value.bodyEs
          : bodyEs // ignore: cast_nullable_to_non_nullable
              as String,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DiseaseImpl implements _Disease {
  const _$DiseaseImpl(
      {required this.id,
      required this.slug,
      required this.titlePt,
      required this.titleEs,
      required this.bodyPt,
      required this.bodyEs,
      required this.isPremium,
      required this.status});

  @override
  final String id;
  @override
  final String slug;
  @override
  final String titlePt;
  @override
  final String titleEs;
  @override
  final String bodyPt;
  @override
  final String bodyEs;
  @override
  final bool isPremium;
  @override
  final String status;

  @override
  String toString() {
    return 'Disease(id: $id, slug: $slug, titlePt: $titlePt, titleEs: $titleEs, bodyPt: $bodyPt, bodyEs: $bodyEs, isPremium: $isPremium, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiseaseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.titlePt, titlePt) || other.titlePt == titlePt) &&
            (identical(other.titleEs, titleEs) || other.titleEs == titleEs) &&
            (identical(other.bodyPt, bodyPt) || other.bodyPt == bodyPt) &&
            (identical(other.bodyEs, bodyEs) || other.bodyEs == bodyEs) &&
            (identical(other.isPremium, isPremium) ||
                other.isPremium == isPremium) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, slug, titlePt, titleEs,
      bodyPt, bodyEs, isPremium, status);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DiseaseImplCopyWith<_$DiseaseImpl> get copyWith =>
      __$$DiseaseImplCopyWithImpl<_$DiseaseImpl>(this, _$identity);
}

abstract class _Disease implements Disease {
  const factory _Disease(
      {required final String id,
      required final String slug,
      required final String titlePt,
      required final String titleEs,
      required final String bodyPt,
      required final String bodyEs,
      required final bool isPremium,
      required final String status}) = _$DiseaseImpl;

  @override
  String get id;
  @override
  String get slug;
  @override
  String get titlePt;
  @override
  String get titleEs;
  @override
  String get bodyPt;
  @override
  String get bodyEs;
  @override
  bool get isPremium;
  @override
  String get status;
  @override
  @JsonKey(ignore: true)
  _$$DiseaseImplCopyWith<_$DiseaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
