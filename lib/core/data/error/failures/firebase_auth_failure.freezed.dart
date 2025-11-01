// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'firebase_auth_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FirebaseAuthFailure {
  String get message => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) operationNotAllowed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? operationNotAllowed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? operationNotAllowed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OperationNotAllowed value) operationNotAllowed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OperationNotAllowed value)? operationNotAllowed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OperationNotAllowed value)? operationNotAllowed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of FirebaseAuthFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FirebaseAuthFailureCopyWith<FirebaseAuthFailure> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FirebaseAuthFailureCopyWith<$Res> {
  factory $FirebaseAuthFailureCopyWith(
          FirebaseAuthFailure value, $Res Function(FirebaseAuthFailure) then) =
      _$FirebaseAuthFailureCopyWithImpl<$Res, FirebaseAuthFailure>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$FirebaseAuthFailureCopyWithImpl<$Res, $Val extends FirebaseAuthFailure>
    implements $FirebaseAuthFailureCopyWith<$Res> {
  _$FirebaseAuthFailureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FirebaseAuthFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_value.copyWith(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OperationNotAllowedImplCopyWith<$Res>
    implements $FirebaseAuthFailureCopyWith<$Res> {
  factory _$$OperationNotAllowedImplCopyWith(_$OperationNotAllowedImpl value,
          $Res Function(_$OperationNotAllowedImpl) then) =
      __$$OperationNotAllowedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$OperationNotAllowedImplCopyWithImpl<$Res>
    extends _$FirebaseAuthFailureCopyWithImpl<$Res, _$OperationNotAllowedImpl>
    implements _$$OperationNotAllowedImplCopyWith<$Res> {
  __$$OperationNotAllowedImplCopyWithImpl(_$OperationNotAllowedImpl _value,
      $Res Function(_$OperationNotAllowedImpl) _then)
      : super(_value, _then);

  /// Create a copy of FirebaseAuthFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$OperationNotAllowedImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$OperationNotAllowedImpl implements OperationNotAllowed {
  const _$OperationNotAllowedImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'FirebaseAuthFailure.operationNotAllowed(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OperationNotAllowedImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of FirebaseAuthFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OperationNotAllowedImplCopyWith<_$OperationNotAllowedImpl> get copyWith =>
      __$$OperationNotAllowedImplCopyWithImpl<_$OperationNotAllowedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) operationNotAllowed,
  }) {
    return operationNotAllowed(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? operationNotAllowed,
  }) {
    return operationNotAllowed?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? operationNotAllowed,
    required TResult orElse(),
  }) {
    if (operationNotAllowed != null) {
      return operationNotAllowed(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OperationNotAllowed value) operationNotAllowed,
  }) {
    return operationNotAllowed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OperationNotAllowed value)? operationNotAllowed,
  }) {
    return operationNotAllowed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OperationNotAllowed value)? operationNotAllowed,
    required TResult orElse(),
  }) {
    if (operationNotAllowed != null) {
      return operationNotAllowed(this);
    }
    return orElse();
  }
}

abstract class OperationNotAllowed implements FirebaseAuthFailure {
  const factory OperationNotAllowed({required final String message}) =
      _$OperationNotAllowedImpl;

  @override
  String get message;

  /// Create a copy of FirebaseAuthFailure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OperationNotAllowedImplCopyWith<_$OperationNotAllowedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
