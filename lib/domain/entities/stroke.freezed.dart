// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stroke.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Stroke {
  List<Offset> get points => throw _privateConstructorUsedError;
  Color get color => throw _privateConstructorUsedError;
  double get strokeWidth => throw _privateConstructorUsedError;
  bool get isEraser => throw _privateConstructorUsedError;
  StrokeType get type => throw _privateConstructorUsedError;
  String? get text => throw _privateConstructorUsedError;
  String? get iconPath => throw _privateConstructorUsedError;

  /// Create a copy of Stroke
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StrokeCopyWith<Stroke> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StrokeCopyWith<$Res> {
  factory $StrokeCopyWith(Stroke value, $Res Function(Stroke) then) =
      _$StrokeCopyWithImpl<$Res, Stroke>;
  @useResult
  $Res call({
    List<Offset> points,
    Color color,
    double strokeWidth,
    bool isEraser,
    StrokeType type,
    String? text,
    String? iconPath,
  });
}

/// @nodoc
class _$StrokeCopyWithImpl<$Res, $Val extends Stroke>
    implements $StrokeCopyWith<$Res> {
  _$StrokeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Stroke
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? points = null,
    Object? color = null,
    Object? strokeWidth = null,
    Object? isEraser = null,
    Object? type = null,
    Object? text = freezed,
    Object? iconPath = freezed,
  }) {
    return _then(
      _value.copyWith(
            points: null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as List<Offset>,
            color: null == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as Color,
            strokeWidth: null == strokeWidth
                ? _value.strokeWidth
                : strokeWidth // ignore: cast_nullable_to_non_nullable
                      as double,
            isEraser: null == isEraser
                ? _value.isEraser
                : isEraser // ignore: cast_nullable_to_non_nullable
                      as bool,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as StrokeType,
            text: freezed == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String?,
            iconPath: freezed == iconPath
                ? _value.iconPath
                : iconPath // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StrokeImplCopyWith<$Res> implements $StrokeCopyWith<$Res> {
  factory _$$StrokeImplCopyWith(
    _$StrokeImpl value,
    $Res Function(_$StrokeImpl) then,
  ) = __$$StrokeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Offset> points,
    Color color,
    double strokeWidth,
    bool isEraser,
    StrokeType type,
    String? text,
    String? iconPath,
  });
}

/// @nodoc
class __$$StrokeImplCopyWithImpl<$Res>
    extends _$StrokeCopyWithImpl<$Res, _$StrokeImpl>
    implements _$$StrokeImplCopyWith<$Res> {
  __$$StrokeImplCopyWithImpl(
    _$StrokeImpl _value,
    $Res Function(_$StrokeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Stroke
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? points = null,
    Object? color = null,
    Object? strokeWidth = null,
    Object? isEraser = null,
    Object? type = null,
    Object? text = freezed,
    Object? iconPath = freezed,
  }) {
    return _then(
      _$StrokeImpl(
        points: null == points
            ? _value._points
            : points // ignore: cast_nullable_to_non_nullable
                  as List<Offset>,
        color: null == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as Color,
        strokeWidth: null == strokeWidth
            ? _value.strokeWidth
            : strokeWidth // ignore: cast_nullable_to_non_nullable
                  as double,
        isEraser: null == isEraser
            ? _value.isEraser
            : isEraser // ignore: cast_nullable_to_non_nullable
                  as bool,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as StrokeType,
        text: freezed == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String?,
        iconPath: freezed == iconPath
            ? _value.iconPath
            : iconPath // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$StrokeImpl implements _Stroke {
  const _$StrokeImpl({
    required final List<Offset> points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
    this.type = StrokeType.pen,
    this.text,
    this.iconPath,
  }) : _points = points;

  final List<Offset> _points;
  @override
  List<Offset> get points {
    if (_points is EqualUnmodifiableListView) return _points;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_points);
  }

  @override
  final Color color;
  @override
  final double strokeWidth;
  @override
  @JsonKey()
  final bool isEraser;
  @override
  @JsonKey()
  final StrokeType type;
  @override
  final String? text;
  @override
  final String? iconPath;

  @override
  String toString() {
    return 'Stroke(points: $points, color: $color, strokeWidth: $strokeWidth, isEraser: $isEraser, type: $type, text: $text, iconPath: $iconPath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StrokeImpl &&
            const DeepCollectionEquality().equals(other._points, _points) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.strokeWidth, strokeWidth) ||
                other.strokeWidth == strokeWidth) &&
            (identical(other.isEraser, isEraser) ||
                other.isEraser == isEraser) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.iconPath, iconPath) ||
                other.iconPath == iconPath));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_points),
    color,
    strokeWidth,
    isEraser,
    type,
    text,
    iconPath,
  );

  /// Create a copy of Stroke
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StrokeImplCopyWith<_$StrokeImpl> get copyWith =>
      __$$StrokeImplCopyWithImpl<_$StrokeImpl>(this, _$identity);
}

abstract class _Stroke implements Stroke {
  const factory _Stroke({
    required final List<Offset> points,
    required final Color color,
    required final double strokeWidth,
    final bool isEraser,
    final StrokeType type,
    final String? text,
    final String? iconPath,
  }) = _$StrokeImpl;

  @override
  List<Offset> get points;
  @override
  Color get color;
  @override
  double get strokeWidth;
  @override
  bool get isEraser;
  @override
  StrokeType get type;
  @override
  String? get text;
  @override
  String? get iconPath;

  /// Create a copy of Stroke
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StrokeImplCopyWith<_$StrokeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
