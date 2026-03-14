// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'selection_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SelectionState {
  Problem? get selectedProblem => throw _privateConstructorUsedError;
  String get currentList => throw _privateConstructorUsedError;
  bool get isViewingDetail => throw _privateConstructorUsedError;

  /// Create a copy of SelectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SelectionStateCopyWith<SelectionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SelectionStateCopyWith<$Res> {
  factory $SelectionStateCopyWith(
    SelectionState value,
    $Res Function(SelectionState) then,
  ) = _$SelectionStateCopyWithImpl<$Res, SelectionState>;
  @useResult
  $Res call({
    Problem? selectedProblem,
    String currentList,
    bool isViewingDetail,
  });

  $ProblemCopyWith<$Res>? get selectedProblem;
}

/// @nodoc
class _$SelectionStateCopyWithImpl<$Res, $Val extends SelectionState>
    implements $SelectionStateCopyWith<$Res> {
  _$SelectionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SelectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedProblem = freezed,
    Object? currentList = null,
    Object? isViewingDetail = null,
  }) {
    return _then(
      _value.copyWith(
            selectedProblem: freezed == selectedProblem
                ? _value.selectedProblem
                : selectedProblem // ignore: cast_nullable_to_non_nullable
                      as Problem?,
            currentList: null == currentList
                ? _value.currentList
                : currentList // ignore: cast_nullable_to_non_nullable
                      as String,
            isViewingDetail: null == isViewingDetail
                ? _value.isViewingDetail
                : isViewingDetail // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of SelectionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProblemCopyWith<$Res>? get selectedProblem {
    if (_value.selectedProblem == null) {
      return null;
    }

    return $ProblemCopyWith<$Res>(_value.selectedProblem!, (value) {
      return _then(_value.copyWith(selectedProblem: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SelectionStateImplCopyWith<$Res>
    implements $SelectionStateCopyWith<$Res> {
  factory _$$SelectionStateImplCopyWith(
    _$SelectionStateImpl value,
    $Res Function(_$SelectionStateImpl) then,
  ) = __$$SelectionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Problem? selectedProblem,
    String currentList,
    bool isViewingDetail,
  });

  @override
  $ProblemCopyWith<$Res>? get selectedProblem;
}

/// @nodoc
class __$$SelectionStateImplCopyWithImpl<$Res>
    extends _$SelectionStateCopyWithImpl<$Res, _$SelectionStateImpl>
    implements _$$SelectionStateImplCopyWith<$Res> {
  __$$SelectionStateImplCopyWithImpl(
    _$SelectionStateImpl _value,
    $Res Function(_$SelectionStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SelectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedProblem = freezed,
    Object? currentList = null,
    Object? isViewingDetail = null,
  }) {
    return _then(
      _$SelectionStateImpl(
        selectedProblem: freezed == selectedProblem
            ? _value.selectedProblem
            : selectedProblem // ignore: cast_nullable_to_non_nullable
                  as Problem?,
        currentList: null == currentList
            ? _value.currentList
            : currentList // ignore: cast_nullable_to_non_nullable
                  as String,
        isViewingDetail: null == isViewingDetail
            ? _value.isViewingDetail
            : isViewingDetail // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$SelectionStateImpl implements _SelectionState {
  const _$SelectionStateImpl({
    this.selectedProblem,
    this.currentList = 'Pareto 49',
    this.isViewingDetail = false,
  });

  @override
  final Problem? selectedProblem;
  @override
  @JsonKey()
  final String currentList;
  @override
  @JsonKey()
  final bool isViewingDetail;

  @override
  String toString() {
    return 'SelectionState(selectedProblem: $selectedProblem, currentList: $currentList, isViewingDetail: $isViewingDetail)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SelectionStateImpl &&
            (identical(other.selectedProblem, selectedProblem) ||
                other.selectedProblem == selectedProblem) &&
            (identical(other.currentList, currentList) ||
                other.currentList == currentList) &&
            (identical(other.isViewingDetail, isViewingDetail) ||
                other.isViewingDetail == isViewingDetail));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, selectedProblem, currentList, isViewingDetail);

  /// Create a copy of SelectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SelectionStateImplCopyWith<_$SelectionStateImpl> get copyWith =>
      __$$SelectionStateImplCopyWithImpl<_$SelectionStateImpl>(
        this,
        _$identity,
      );
}

abstract class _SelectionState implements SelectionState {
  const factory _SelectionState({
    final Problem? selectedProblem,
    final String currentList,
    final bool isViewingDetail,
  }) = _$SelectionStateImpl;

  @override
  Problem? get selectedProblem;
  @override
  String get currentList;
  @override
  bool get isViewingDetail;

  /// Create a copy of SelectionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SelectionStateImplCopyWith<_$SelectionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
