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
  Map<String, List<Stroke>> get boards => throw _privateConstructorUsedError;
  String get activeBoardId => throw _privateConstructorUsedError;
  List<String> get boardIds => throw _privateConstructorUsedError;
  List<Stroke> get redoStack => throw _privateConstructorUsedError;
  Map<String, String?> get boardProblems =>
      throw _privateConstructorUsedError; // boardId -> problemId
  bool get isDrawing => throw _privateConstructorUsedError;
  bool get isLoaded => throw _privateConstructorUsedError;
  int? get selectedStrokeIndex => throw _privateConstructorUsedError;

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
  $Res call({
    Map<String, List<Stroke>> boards,
    String activeBoardId,
    List<String> boardIds,
    List<Stroke> redoStack,
    Map<String, String?> boardProblems,
    bool isDrawing,
    bool isLoaded,
    int? selectedStrokeIndex,
  });
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
    Object? boards = null,
    Object? activeBoardId = null,
    Object? boardIds = null,
    Object? redoStack = null,
    Object? boardProblems = null,
    Object? isDrawing = null,
    Object? isLoaded = null,
    Object? selectedStrokeIndex = freezed,
  }) {
    return _then(
      _value.copyWith(
            boards: null == boards
                ? _value.boards
                : boards // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<Stroke>>,
            activeBoardId: null == activeBoardId
                ? _value.activeBoardId
                : activeBoardId // ignore: cast_nullable_to_non_nullable
                      as String,
            boardIds: null == boardIds
                ? _value.boardIds
                : boardIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            redoStack: null == redoStack
                ? _value.redoStack
                : redoStack // ignore: cast_nullable_to_non_nullable
                      as List<Stroke>,
            boardProblems: null == boardProblems
                ? _value.boardProblems
                : boardProblems // ignore: cast_nullable_to_non_nullable
                      as Map<String, String?>,
            isDrawing: null == isDrawing
                ? _value.isDrawing
                : isDrawing // ignore: cast_nullable_to_non_nullable
                      as bool,
            isLoaded: null == isLoaded
                ? _value.isLoaded
                : isLoaded // ignore: cast_nullable_to_non_nullable
                      as bool,
            selectedStrokeIndex: freezed == selectedStrokeIndex
                ? _value.selectedStrokeIndex
                : selectedStrokeIndex // ignore: cast_nullable_to_non_nullable
                      as int?,
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
  $Res call({
    Map<String, List<Stroke>> boards,
    String activeBoardId,
    List<String> boardIds,
    List<Stroke> redoStack,
    Map<String, String?> boardProblems,
    bool isDrawing,
    bool isLoaded,
    int? selectedStrokeIndex,
  });
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
    Object? boards = null,
    Object? activeBoardId = null,
    Object? boardIds = null,
    Object? redoStack = null,
    Object? boardProblems = null,
    Object? isDrawing = null,
    Object? isLoaded = null,
    Object? selectedStrokeIndex = freezed,
  }) {
    return _then(
      _$DrawingStateImpl(
        boards: null == boards
            ? _value._boards
            : boards // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<Stroke>>,
        activeBoardId: null == activeBoardId
            ? _value.activeBoardId
            : activeBoardId // ignore: cast_nullable_to_non_nullable
                  as String,
        boardIds: null == boardIds
            ? _value._boardIds
            : boardIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        redoStack: null == redoStack
            ? _value._redoStack
            : redoStack // ignore: cast_nullable_to_non_nullable
                  as List<Stroke>,
        boardProblems: null == boardProblems
            ? _value._boardProblems
            : boardProblems // ignore: cast_nullable_to_non_nullable
                  as Map<String, String?>,
        isDrawing: null == isDrawing
            ? _value.isDrawing
            : isDrawing // ignore: cast_nullable_to_non_nullable
                  as bool,
        isLoaded: null == isLoaded
            ? _value.isLoaded
            : isLoaded // ignore: cast_nullable_to_non_nullable
                  as bool,
        selectedStrokeIndex: freezed == selectedStrokeIndex
            ? _value.selectedStrokeIndex
            : selectedStrokeIndex // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$DrawingStateImpl extends _DrawingState {
  const _$DrawingStateImpl({
    required final Map<String, List<Stroke>> boards,
    required this.activeBoardId,
    required final List<String> boardIds,
    required final List<Stroke> redoStack,
    final Map<String, String?> boardProblems = const {},
    this.isDrawing = false,
    this.isLoaded = false,
    this.selectedStrokeIndex,
  }) : _boards = boards,
       _boardIds = boardIds,
       _redoStack = redoStack,
       _boardProblems = boardProblems,
       super._();

  final Map<String, List<Stroke>> _boards;
  @override
  Map<String, List<Stroke>> get boards {
    if (_boards is EqualUnmodifiableMapView) return _boards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_boards);
  }

  @override
  final String activeBoardId;
  final List<String> _boardIds;
  @override
  List<String> get boardIds {
    if (_boardIds is EqualUnmodifiableListView) return _boardIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_boardIds);
  }

  final List<Stroke> _redoStack;
  @override
  List<Stroke> get redoStack {
    if (_redoStack is EqualUnmodifiableListView) return _redoStack;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_redoStack);
  }

  final Map<String, String?> _boardProblems;
  @override
  @JsonKey()
  Map<String, String?> get boardProblems {
    if (_boardProblems is EqualUnmodifiableMapView) return _boardProblems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_boardProblems);
  }

  // boardId -> problemId
  @override
  @JsonKey()
  final bool isDrawing;
  @override
  @JsonKey()
  final bool isLoaded;
  @override
  final int? selectedStrokeIndex;

  @override
  String toString() {
    return 'DrawingState(boards: $boards, activeBoardId: $activeBoardId, boardIds: $boardIds, redoStack: $redoStack, boardProblems: $boardProblems, isDrawing: $isDrawing, isLoaded: $isLoaded, selectedStrokeIndex: $selectedStrokeIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DrawingStateImpl &&
            const DeepCollectionEquality().equals(other._boards, _boards) &&
            (identical(other.activeBoardId, activeBoardId) ||
                other.activeBoardId == activeBoardId) &&
            const DeepCollectionEquality().equals(other._boardIds, _boardIds) &&
            const DeepCollectionEquality().equals(
              other._redoStack,
              _redoStack,
            ) &&
            const DeepCollectionEquality().equals(
              other._boardProblems,
              _boardProblems,
            ) &&
            (identical(other.isDrawing, isDrawing) ||
                other.isDrawing == isDrawing) &&
            (identical(other.isLoaded, isLoaded) ||
                other.isLoaded == isLoaded) &&
            (identical(other.selectedStrokeIndex, selectedStrokeIndex) ||
                other.selectedStrokeIndex == selectedStrokeIndex));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_boards),
    activeBoardId,
    const DeepCollectionEquality().hash(_boardIds),
    const DeepCollectionEquality().hash(_redoStack),
    const DeepCollectionEquality().hash(_boardProblems),
    isDrawing,
    isLoaded,
    selectedStrokeIndex,
  );

  /// Create a copy of DrawingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DrawingStateImplCopyWith<_$DrawingStateImpl> get copyWith =>
      __$$DrawingStateImplCopyWithImpl<_$DrawingStateImpl>(this, _$identity);
}

abstract class _DrawingState extends DrawingState {
  const factory _DrawingState({
    required final Map<String, List<Stroke>> boards,
    required final String activeBoardId,
    required final List<String> boardIds,
    required final List<Stroke> redoStack,
    final Map<String, String?> boardProblems,
    final bool isDrawing,
    final bool isLoaded,
    final int? selectedStrokeIndex,
  }) = _$DrawingStateImpl;
  const _DrawingState._() : super._();

  @override
  Map<String, List<Stroke>> get boards;
  @override
  String get activeBoardId;
  @override
  List<String> get boardIds;
  @override
  List<Stroke> get redoStack;
  @override
  Map<String, String?> get boardProblems; // boardId -> problemId
  @override
  bool get isDrawing;
  @override
  bool get isLoaded;
  @override
  int? get selectedStrokeIndex;

  /// Create a copy of DrawingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DrawingStateImplCopyWith<_$DrawingStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
