// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drawing_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DrawingState {
  List<Stroke> get strokes => throw _privateConstructorUsedError;
  List<Stroke> get redoStack => throw _privateConstructorUsedError;
  bool get isDrawing => throw _privateConstructorUsedError;

  /// Create a copy of DrawingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DrawingStateCopyWith<DrawingState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DrawingStateCopyWith<$Res> {
  factory $DrawingStateCopyWith(
    DrawingState value,
    $Res Function(DrawingState) then,
  ) = _$DrawingStateCopyWithImpl<$Res, DrawingState>;
  @useResult
  $Res call({List<Stroke> strokes, List<Stroke> redoStack, bool isDrawing});
}

/// @nodoc
class _$DrawingStateCopyWithImpl<$Res, $Val extends DrawingState>
    implements $DrawingStateCopyWith<$Res> {
  _$DrawingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DrawingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? strokes = null,
    Object? redoStack = null,
    Object? isDrawing = null,
  }) {
    return _then(
      _value.copyWith(
            strokes: null == strokes
                ? _value.strokes
                : strokes // ignore: cast_nullable_to_non_nullable
                      as List<Stroke>,
            redoStack: null == redoStack
                ? _value.redoStack
                : redoStack // ignore: cast_nullable_to_non_nullable
                      as List<Stroke>,
            isDrawing: null == isDrawing
                ? _value.isDrawing
                : isDrawing // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DrawingStateImplCopyWith<$Res>
    implements $DrawingStateCopyWith<$Res> {
  factory _$$DrawingStateImplCopyWith(
    _$DrawingStateImpl value,
    $Res Function(_$DrawingStateImpl) then,
  ) = __$$DrawingStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Stroke> strokes, List<Stroke> redoStack, bool isDrawing});
}

/// @nodoc
class __$$DrawingStateImplCopyWithImpl<$Res>
    extends _$DrawingStateCopyWithImpl<$Res, _$DrawingStateImpl>
    implements _$$DrawingStateImplCopyWith<$Res> {
  __$$DrawingStateImplCopyWithImpl(
    _$DrawingStateImpl _value,
    $Res Function(_$DrawingStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DrawingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? strokes = null,
    Object? redoStack = null,
    Object? isDrawing = null,
  }) {
    return _then(
      _$DrawingStateImpl(
        strokes: null == strokes
            ? _value._strokes
            : strokes // ignore: cast_nullable_to_non_nullable
                  as List<Stroke>,
        redoStack: null == redoStack
            ? _value._redoStack
            : redoStack // ignore: cast_nullable_to_non_nullable
                  as List<Stroke>,
        isDrawing: null == isDrawing
            ? _value.isDrawing
            : isDrawing // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$DrawingStateImpl implements _DrawingState {
  const _$DrawingStateImpl({
    required final List<Stroke> strokes,
    required final List<Stroke> redoStack,
    this.isDrawing = false,
  }) : _strokes = strokes,
       _redoStack = redoStack;

  final List<Stroke> _strokes;
  @override
  List<Stroke> get strokes {
    if (_strokes is EqualUnmodifiableListView) return _strokes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_strokes);
  }

  final List<Stroke> _redoStack;
  @override
  List<Stroke> get redoStack {
    if (_redoStack is EqualUnmodifiableListView) return _redoStack;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_redoStack);
  }

  @override
  @JsonKey()
  final bool isDrawing;

  @override
  String toString() {
    return 'DrawingState(strokes: $strokes, redoStack: $redoStack, isDrawing: $isDrawing)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DrawingStateImpl &&
            const DeepCollectionEquality().equals(other._strokes, _strokes) &&
            const DeepCollectionEquality().equals(
              other._redoStack,
              _redoStack,
            ) &&
            (identical(other.isDrawing, isDrawing) ||
                other.isDrawing == isDrawing));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_strokes),
    const DeepCollectionEquality().hash(_redoStack),
    isDrawing,
  );

  /// Create a copy of DrawingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DrawingStateImplCopyWith<_$DrawingStateImpl> get copyWith =>
      __$$DrawingStateImplCopyWithImpl<_$DrawingStateImpl>(this, _$identity);
}

abstract class _DrawingState implements DrawingState {
  const factory _DrawingState({
    required final List<Stroke> strokes,
    required final List<Stroke> redoStack,
    final bool isDrawing,
  }) = _$DrawingStateImpl;

  @override
  List<Stroke> get strokes;
  @override
  List<Stroke> get redoStack;
  @override
  bool get isDrawing;

  /// Create a copy of DrawingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DrawingStateImplCopyWith<_$DrawingStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
