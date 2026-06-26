// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_drawing_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LiveDrawingState {
  Stroke? get activeStroke => throw _privateConstructorUsedError;
  Offset? get hoverPosition => throw _privateConstructorUsedError;
  int get revision => throw _privateConstructorUsedError;

  /// Create a copy of LiveDrawingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LiveDrawingStateCopyWith<LiveDrawingState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LiveDrawingStateCopyWith<$Res> {
  factory $LiveDrawingStateCopyWith(
    LiveDrawingState value,
    $Res Function(LiveDrawingState) then,
  ) = _$LiveDrawingStateCopyWithImpl<$Res, LiveDrawingState>;
  @useResult
  $Res call({Stroke? activeStroke, Offset? hoverPosition, int revision});

  $StrokeCopyWith<$Res>? get activeStroke;
}

/// @nodoc
class _$LiveDrawingStateCopyWithImpl<$Res, $Val extends LiveDrawingState>
    implements $LiveDrawingStateCopyWith<$Res> {
  _$LiveDrawingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LiveDrawingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeStroke = freezed,
    Object? hoverPosition = freezed,
    Object? revision = null,
  }) {
    return _then(
      _value.copyWith(
            activeStroke: freezed == activeStroke
                ? _value.activeStroke
                : activeStroke // ignore: cast_nullable_to_non_nullable
                      as Stroke?,
            hoverPosition: freezed == hoverPosition
                ? _value.hoverPosition
                : hoverPosition // ignore: cast_nullable_to_non_nullable
                      as Offset?,
            revision: null == revision
                ? _value.revision
                : revision // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }

  /// Create a copy of LiveDrawingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StrokeCopyWith<$Res>? get activeStroke {
    if (_value.activeStroke == null) {
      return null;
    }

    return $StrokeCopyWith<$Res>(_value.activeStroke!, (value) {
      return _then(_value.copyWith(activeStroke: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LiveDrawingStateImplCopyWith<$Res>
    implements $LiveDrawingStateCopyWith<$Res> {
  factory _$$LiveDrawingStateImplCopyWith(
    _$LiveDrawingStateImpl value,
    $Res Function(_$LiveDrawingStateImpl) then,
  ) = __$$LiveDrawingStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Stroke? activeStroke, Offset? hoverPosition, int revision});

  @override
  $StrokeCopyWith<$Res>? get activeStroke;
}

/// @nodoc
class __$$LiveDrawingStateImplCopyWithImpl<$Res>
    extends _$LiveDrawingStateCopyWithImpl<$Res, _$LiveDrawingStateImpl>
    implements _$$LiveDrawingStateImplCopyWith<$Res> {
  __$$LiveDrawingStateImplCopyWithImpl(
    _$LiveDrawingStateImpl _value,
    $Res Function(_$LiveDrawingStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LiveDrawingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeStroke = freezed,
    Object? hoverPosition = freezed,
    Object? revision = null,
  }) {
    return _then(
      _$LiveDrawingStateImpl(
        activeStroke: freezed == activeStroke
            ? _value.activeStroke
            : activeStroke // ignore: cast_nullable_to_non_nullable
                  as Stroke?,
        hoverPosition: freezed == hoverPosition
            ? _value.hoverPosition
            : hoverPosition // ignore: cast_nullable_to_non_nullable
                  as Offset?,
        revision: null == revision
            ? _value.revision
            : revision // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$LiveDrawingStateImpl implements _LiveDrawingState {
  const _$LiveDrawingStateImpl({
    this.activeStroke,
    this.hoverPosition,
    this.revision = 0,
  });

  @override
  final Stroke? activeStroke;
  @override
  final Offset? hoverPosition;
  @override
  @JsonKey()
  final int revision;

  @override
  String toString() {
    return 'LiveDrawingState(activeStroke: $activeStroke, hoverPosition: $hoverPosition, revision: $revision)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LiveDrawingStateImpl &&
            (identical(other.activeStroke, activeStroke) ||
                other.activeStroke == activeStroke) &&
            (identical(other.hoverPosition, hoverPosition) ||
                other.hoverPosition == hoverPosition) &&
            (identical(other.revision, revision) ||
                other.revision == revision));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, activeStroke, hoverPosition, revision);

  /// Create a copy of LiveDrawingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LiveDrawingStateImplCopyWith<_$LiveDrawingStateImpl> get copyWith =>
      __$$LiveDrawingStateImplCopyWithImpl<_$LiveDrawingStateImpl>(
        this,
        _$identity,
      );
}

abstract class _LiveDrawingState implements LiveDrawingState {
  const factory _LiveDrawingState({
    final Stroke? activeStroke,
    final Offset? hoverPosition,
    final int revision,
  }) = _$LiveDrawingStateImpl;

  @override
  Stroke? get activeStroke;
  @override
  Offset? get hoverPosition;
  @override
  int get revision;

  /// Create a copy of LiveDrawingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LiveDrawingStateImplCopyWith<_$LiveDrawingStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
