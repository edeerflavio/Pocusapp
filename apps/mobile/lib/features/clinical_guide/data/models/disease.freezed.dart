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
  String get titlePt => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get cid => throw _privateConstructorUsedError;
  String get treatment => throw _privateConstructorUsedError;

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
      String titlePt,
      String description,
      String cid,
      String treatment});
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
    Object? titlePt = null,
    Object? description = null,
    Object? cid = null,
    Object? treatment = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      titlePt: null == titlePt
          ? _value.titlePt
          : titlePt // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      cid: null == cid
          ? _value.cid
          : cid // ignore: cast_nullable_to_non_nullable
              as String,
      treatment: null == treatment
          ? _value.treatment
          : treatment // ignore: cast_nullable_to_non_nullable
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
      String titlePt,
      String description,
      String cid,
      String treatment});
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
    Object? titlePt = null,
    Object? description = null,
    Object? cid = null,
    Object? treatment = null,
  }) {
    return _then(_$DiseaseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      titlePt: null == titlePt
          ? _value.titlePt
          : titlePt // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      cid: null == cid
          ? _value.cid
          : cid // ignore: cast_nullable_to_non_nullable
              as String,
      treatment: null == treatment
          ? _value.treatment
          : treatment // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DiseaseImpl implements _Disease {
  const _$DiseaseImpl(
      {required this.id,
      required this.titlePt,
      required this.description,
      required this.cid,
      required this.treatment});

  @override
  final String id;
  @override
  final String titlePt;
  @override
  final String description;
  @override
  final String cid;
  @override
  final String treatment;

  @override
  String toString() {
    return 'Disease(id: $id, titlePt: $titlePt, description: $description, cid: $cid, treatment: $treatment)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiseaseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.titlePt, titlePt) || other.titlePt == titlePt) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.cid, cid) || other.cid == cid) &&
            (identical(other.treatment, treatment) ||
                other.treatment == treatment));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, titlePt, description, cid, treatment);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DiseaseImplCopyWith<_$DiseaseImpl> get copyWith =>
      __$$DiseaseImplCopyWithImpl<_$DiseaseImpl>(this, _$identity);
}

abstract class _Disease implements Disease {
  const factory _Disease(
      {required final String id,
      required final String titlePt,
      required final String description,
      required final String cid,
      required final String treatment}) = _$DiseaseImpl;

  @override
  String get id;
  @override
  String get titlePt;
  @override
  String get description;
  @override
  String get cid;
  @override
  String get treatment;
  @override
  @JsonKey(ignore: true)
  _$$DiseaseImplCopyWith<_$DiseaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
