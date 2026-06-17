// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gemma_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GemmaState {
  GemmaStatus get status => throw _privateConstructorUsedError;
  double get downloadProgress => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  bool get aiLoading => throw _privateConstructorUsedError;
  String? get aiThinking => throw _privateConstructorUsedError;
  String? get aiResponse => throw _privateConstructorUsedError;
  String? get aiError => throw _privateConstructorUsedError;
  List<UiChatMessage> get chatHistory => throw _privateConstructorUsedError;

  /// Create a copy of GemmaState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GemmaStateCopyWith<GemmaState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GemmaStateCopyWith<$Res> {
  factory $GemmaStateCopyWith(
    GemmaState value,
    $Res Function(GemmaState) then,
  ) = _$GemmaStateCopyWithImpl<$Res, GemmaState>;
  @useResult
  $Res call({
    GemmaStatus status,
    double downloadProgress,
    String? errorMessage,
    bool aiLoading,
    String? aiThinking,
    String? aiResponse,
    String? aiError,
    List<UiChatMessage> chatHistory,
  });
}

/// @nodoc
class _$GemmaStateCopyWithImpl<$Res, $Val extends GemmaState>
    implements $GemmaStateCopyWith<$Res> {
  _$GemmaStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GemmaState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? downloadProgress = null,
    Object? errorMessage = freezed,
    Object? aiLoading = null,
    Object? aiThinking = freezed,
    Object? aiResponse = freezed,
    Object? aiError = freezed,
    Object? chatHistory = null,
  }) {
    return _then(
      _value.copyWith(
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as GemmaStatus,
            downloadProgress: null == downloadProgress
                ? _value.downloadProgress
                : downloadProgress // ignore: cast_nullable_to_non_nullable
                      as double,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            aiLoading: null == aiLoading
                ? _value.aiLoading
                : aiLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            aiThinking: freezed == aiThinking
                ? _value.aiThinking
                : aiThinking // ignore: cast_nullable_to_non_nullable
                      as String?,
            aiResponse: freezed == aiResponse
                ? _value.aiResponse
                : aiResponse // ignore: cast_nullable_to_non_nullable
                      as String?,
            aiError: freezed == aiError
                ? _value.aiError
                : aiError // ignore: cast_nullable_to_non_nullable
                      as String?,
            chatHistory: null == chatHistory
                ? _value.chatHistory
                : chatHistory // ignore: cast_nullable_to_non_nullable
                      as List<UiChatMessage>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GemmaStateImplCopyWith<$Res>
    implements $GemmaStateCopyWith<$Res> {
  factory _$$GemmaStateImplCopyWith(
    _$GemmaStateImpl value,
    $Res Function(_$GemmaStateImpl) then,
  ) = __$$GemmaStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    GemmaStatus status,
    double downloadProgress,
    String? errorMessage,
    bool aiLoading,
    String? aiThinking,
    String? aiResponse,
    String? aiError,
    List<UiChatMessage> chatHistory,
  });
}

/// @nodoc
class __$$GemmaStateImplCopyWithImpl<$Res>
    extends _$GemmaStateCopyWithImpl<$Res, _$GemmaStateImpl>
    implements _$$GemmaStateImplCopyWith<$Res> {
  __$$GemmaStateImplCopyWithImpl(
    _$GemmaStateImpl _value,
    $Res Function(_$GemmaStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GemmaState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? downloadProgress = null,
    Object? errorMessage = freezed,
    Object? aiLoading = null,
    Object? aiThinking = freezed,
    Object? aiResponse = freezed,
    Object? aiError = freezed,
    Object? chatHistory = null,
  }) {
    return _then(
      _$GemmaStateImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as GemmaStatus,
        downloadProgress: null == downloadProgress
            ? _value.downloadProgress
            : downloadProgress // ignore: cast_nullable_to_non_nullable
                  as double,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        aiLoading: null == aiLoading
            ? _value.aiLoading
            : aiLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        aiThinking: freezed == aiThinking
            ? _value.aiThinking
            : aiThinking // ignore: cast_nullable_to_non_nullable
                  as String?,
        aiResponse: freezed == aiResponse
            ? _value.aiResponse
            : aiResponse // ignore: cast_nullable_to_non_nullable
                  as String?,
        aiError: freezed == aiError
            ? _value.aiError
            : aiError // ignore: cast_nullable_to_non_nullable
                  as String?,
        chatHistory: null == chatHistory
            ? _value._chatHistory
            : chatHistory // ignore: cast_nullable_to_non_nullable
                  as List<UiChatMessage>,
      ),
    );
  }
}

/// @nodoc

class _$GemmaStateImpl implements _GemmaState {
  const _$GemmaStateImpl({
    this.status = GemmaStatus.idle,
    this.downloadProgress = 0.0,
    this.errorMessage,
    this.aiLoading = false,
    this.aiThinking,
    this.aiResponse,
    this.aiError,
    final List<UiChatMessage> chatHistory = const [],
  }) : _chatHistory = chatHistory;

  @override
  @JsonKey()
  final GemmaStatus status;
  @override
  @JsonKey()
  final double downloadProgress;
  @override
  final String? errorMessage;
  @override
  @JsonKey()
  final bool aiLoading;
  @override
  final String? aiThinking;
  @override
  final String? aiResponse;
  @override
  final String? aiError;
  final List<UiChatMessage> _chatHistory;
  @override
  @JsonKey()
  List<UiChatMessage> get chatHistory {
    if (_chatHistory is EqualUnmodifiableListView) return _chatHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chatHistory);
  }

  @override
  String toString() {
    return 'GemmaState(status: $status, downloadProgress: $downloadProgress, errorMessage: $errorMessage, aiLoading: $aiLoading, aiThinking: $aiThinking, aiResponse: $aiResponse, aiError: $aiError, chatHistory: $chatHistory)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GemmaStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.downloadProgress, downloadProgress) ||
                other.downloadProgress == downloadProgress) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.aiLoading, aiLoading) ||
                other.aiLoading == aiLoading) &&
            (identical(other.aiThinking, aiThinking) ||
                other.aiThinking == aiThinking) &&
            (identical(other.aiResponse, aiResponse) ||
                other.aiResponse == aiResponse) &&
            (identical(other.aiError, aiError) || other.aiError == aiError) &&
            const DeepCollectionEquality().equals(
              other._chatHistory,
              _chatHistory,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    downloadProgress,
    errorMessage,
    aiLoading,
    aiThinking,
    aiResponse,
    aiError,
    const DeepCollectionEquality().hash(_chatHistory),
  );

  /// Create a copy of GemmaState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GemmaStateImplCopyWith<_$GemmaStateImpl> get copyWith =>
      __$$GemmaStateImplCopyWithImpl<_$GemmaStateImpl>(this, _$identity);
}

abstract class _GemmaState implements GemmaState {
  const factory _GemmaState({
    final GemmaStatus status,
    final double downloadProgress,
    final String? errorMessage,
    final bool aiLoading,
    final String? aiThinking,
    final String? aiResponse,
    final String? aiError,
    final List<UiChatMessage> chatHistory,
  }) = _$GemmaStateImpl;

  @override
  GemmaStatus get status;
  @override
  double get downloadProgress;
  @override
  String? get errorMessage;
  @override
  bool get aiLoading;
  @override
  String? get aiThinking;
  @override
  String? get aiResponse;
  @override
  String? get aiError;
  @override
  List<UiChatMessage> get chatHistory;

  /// Create a copy of GemmaState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GemmaStateImplCopyWith<_$GemmaStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
