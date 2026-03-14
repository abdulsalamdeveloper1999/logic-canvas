// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progress_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ProgressState {
  Set<String> get completedProblemIds => throw _privateConstructorUsedError;

  /// Create a copy of ProgressState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProgressStateCopyWith<ProgressState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProgressStateCopyWith<$Res> {
  factory $ProgressStateCopyWith(
    ProgressState value,
    $Res Function(ProgressState) then,
  ) = _$ProgressStateCopyWithImpl<$Res, ProgressState>;
  @useResult
  $Res call({Set<String> completedProblemIds});
}

/// @nodoc
class _$ProgressStateCopyWithImpl<$Res, $Val extends ProgressState>
    implements $ProgressStateCopyWith<$Res> {
  _$ProgressStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProgressState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? completedProblemIds = null}) {
    return _then(
      _value.copyWith(
            completedProblemIds: null == completedProblemIds
                ? _value.completedProblemIds
                : completedProblemIds // ignore: cast_nullable_to_non_nullable
                      as Set<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProgressStateImplCopyWith<$Res>
    implements $ProgressStateCopyWith<$Res> {
  factory _$$ProgressStateImplCopyWith(
    _$ProgressStateImpl value,
    $Res Function(_$ProgressStateImpl) then,
  ) = __$$ProgressStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Set<String> completedProblemIds});
}

/// @nodoc
class __$$ProgressStateImplCopyWithImpl<$Res>
    extends _$ProgressStateCopyWithImpl<$Res, _$ProgressStateImpl>
    implements _$$ProgressStateImplCopyWith<$Res> {
  __$$ProgressStateImplCopyWithImpl(
    _$ProgressStateImpl _value,
    $Res Function(_$ProgressStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProgressState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? completedProblemIds = null}) {
    return _then(
      _$ProgressStateImpl(
        completedProblemIds: null == completedProblemIds
            ? _value._completedProblemIds
            : completedProblemIds // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
      ),
    );
  }
}

/// @nodoc

class _$ProgressStateImpl implements _ProgressState {
  const _$ProgressStateImpl({final Set<String> completedProblemIds = const {}})
    : _completedProblemIds = completedProblemIds;

  final Set<String> _completedProblemIds;
  @override
  @JsonKey()
  Set<String> get completedProblemIds {
    if (_completedProblemIds is EqualUnmodifiableSetView)
      return _completedProblemIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_completedProblemIds);
  }

  @override
  String toString() {
    return 'ProgressState(completedProblemIds: $completedProblemIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProgressStateImpl &&
            const DeepCollectionEquality().equals(
              other._completedProblemIds,
              _completedProblemIds,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_completedProblemIds),
  );

  /// Create a copy of ProgressState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProgressStateImplCopyWith<_$ProgressStateImpl> get copyWith =>
      __$$ProgressStateImplCopyWithImpl<_$ProgressStateImpl>(this, _$identity);
}

abstract class _ProgressState implements ProgressState {
  const factory _ProgressState({final Set<String> completedProblemIds}) =
      _$ProgressStateImpl;

  @override
  Set<String> get completedProblemIds;

  /// Create a copy of ProgressState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProgressStateImplCopyWith<_$ProgressStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
