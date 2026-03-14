// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'problem.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ProblemExample {
  String get input => throw _privateConstructorUsedError;
  String get output => throw _privateConstructorUsedError;
  String? get explanation => throw _privateConstructorUsedError;

  /// Create a copy of ProblemExample
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProblemExampleCopyWith<ProblemExample> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProblemExampleCopyWith<$Res> {
  factory $ProblemExampleCopyWith(
    ProblemExample value,
    $Res Function(ProblemExample) then,
  ) = _$ProblemExampleCopyWithImpl<$Res, ProblemExample>;
  @useResult
  $Res call({String input, String output, String? explanation});
}

/// @nodoc
class _$ProblemExampleCopyWithImpl<$Res, $Val extends ProblemExample>
    implements $ProblemExampleCopyWith<$Res> {
  _$ProblemExampleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProblemExample
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? input = null,
    Object? output = null,
    Object? explanation = freezed,
  }) {
    return _then(
      _value.copyWith(
            input: null == input
                ? _value.input
                : input // ignore: cast_nullable_to_non_nullable
                      as String,
            output: null == output
                ? _value.output
                : output // ignore: cast_nullable_to_non_nullable
                      as String,
            explanation: freezed == explanation
                ? _value.explanation
                : explanation // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProblemExampleImplCopyWith<$Res>
    implements $ProblemExampleCopyWith<$Res> {
  factory _$$ProblemExampleImplCopyWith(
    _$ProblemExampleImpl value,
    $Res Function(_$ProblemExampleImpl) then,
  ) = __$$ProblemExampleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String input, String output, String? explanation});
}

/// @nodoc
class __$$ProblemExampleImplCopyWithImpl<$Res>
    extends _$ProblemExampleCopyWithImpl<$Res, _$ProblemExampleImpl>
    implements _$$ProblemExampleImplCopyWith<$Res> {
  __$$ProblemExampleImplCopyWithImpl(
    _$ProblemExampleImpl _value,
    $Res Function(_$ProblemExampleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProblemExample
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? input = null,
    Object? output = null,
    Object? explanation = freezed,
  }) {
    return _then(
      _$ProblemExampleImpl(
        input: null == input
            ? _value.input
            : input // ignore: cast_nullable_to_non_nullable
                  as String,
        output: null == output
            ? _value.output
            : output // ignore: cast_nullable_to_non_nullable
                  as String,
        explanation: freezed == explanation
            ? _value.explanation
            : explanation // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ProblemExampleImpl implements _ProblemExample {
  const _$ProblemExampleImpl({
    required this.input,
    required this.output,
    this.explanation,
  });

  @override
  final String input;
  @override
  final String output;
  @override
  final String? explanation;

  @override
  String toString() {
    return 'ProblemExample(input: $input, output: $output, explanation: $explanation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProblemExampleImpl &&
            (identical(other.input, input) || other.input == input) &&
            (identical(other.output, output) || other.output == output) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation));
  }

  @override
  int get hashCode => Object.hash(runtimeType, input, output, explanation);

  /// Create a copy of ProblemExample
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProblemExampleImplCopyWith<_$ProblemExampleImpl> get copyWith =>
      __$$ProblemExampleImplCopyWithImpl<_$ProblemExampleImpl>(
        this,
        _$identity,
      );
}

abstract class _ProblemExample implements ProblemExample {
  const factory _ProblemExample({
    required final String input,
    required final String output,
    final String? explanation,
  }) = _$ProblemExampleImpl;

  @override
  String get input;
  @override
  String get output;
  @override
  String? get explanation;

  /// Create a copy of ProblemExample
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProblemExampleImplCopyWith<_$ProblemExampleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Problem {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  Difficulty get difficulty => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  List<String> get hints => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<ProblemExample> get examples => throw _privateConstructorUsedError;

  /// Create a copy of Problem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProblemCopyWith<Problem> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProblemCopyWith<$Res> {
  factory $ProblemCopyWith(Problem value, $Res Function(Problem) then) =
      _$ProblemCopyWithImpl<$Res, Problem>;
  @useResult
  $Res call({
    String id,
    String title,
    String url,
    Difficulty difficulty,
    String category,
    List<String> hints,
    String? description,
    List<ProblemExample> examples,
  });
}

/// @nodoc
class _$ProblemCopyWithImpl<$Res, $Val extends Problem>
    implements $ProblemCopyWith<$Res> {
  _$ProblemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Problem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? url = null,
    Object? difficulty = null,
    Object? category = null,
    Object? hints = null,
    Object? description = freezed,
    Object? examples = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            difficulty: null == difficulty
                ? _value.difficulty
                : difficulty // ignore: cast_nullable_to_non_nullable
                      as Difficulty,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            hints: null == hints
                ? _value.hints
                : hints // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            examples: null == examples
                ? _value.examples
                : examples // ignore: cast_nullable_to_non_nullable
                      as List<ProblemExample>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProblemImplCopyWith<$Res> implements $ProblemCopyWith<$Res> {
  factory _$$ProblemImplCopyWith(
    _$ProblemImpl value,
    $Res Function(_$ProblemImpl) then,
  ) = __$$ProblemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String url,
    Difficulty difficulty,
    String category,
    List<String> hints,
    String? description,
    List<ProblemExample> examples,
  });
}

/// @nodoc
class __$$ProblemImplCopyWithImpl<$Res>
    extends _$ProblemCopyWithImpl<$Res, _$ProblemImpl>
    implements _$$ProblemImplCopyWith<$Res> {
  __$$ProblemImplCopyWithImpl(
    _$ProblemImpl _value,
    $Res Function(_$ProblemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Problem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? url = null,
    Object? difficulty = null,
    Object? category = null,
    Object? hints = null,
    Object? description = freezed,
    Object? examples = null,
  }) {
    return _then(
      _$ProblemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        difficulty: null == difficulty
            ? _value.difficulty
            : difficulty // ignore: cast_nullable_to_non_nullable
                  as Difficulty,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        hints: null == hints
            ? _value._hints
            : hints // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        examples: null == examples
            ? _value._examples
            : examples // ignore: cast_nullable_to_non_nullable
                  as List<ProblemExample>,
      ),
    );
  }
}

/// @nodoc

class _$ProblemImpl implements _Problem {
  const _$ProblemImpl({
    required this.id,
    required this.title,
    required this.url,
    required this.difficulty,
    required this.category,
    final List<String> hints = const [],
    this.description,
    final List<ProblemExample> examples = const [],
  }) : _hints = hints,
       _examples = examples;

  @override
  final String id;
  @override
  final String title;
  @override
  final String url;
  @override
  final Difficulty difficulty;
  @override
  final String category;
  final List<String> _hints;
  @override
  @JsonKey()
  List<String> get hints {
    if (_hints is EqualUnmodifiableListView) return _hints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hints);
  }

  @override
  final String? description;
  final List<ProblemExample> _examples;
  @override
  @JsonKey()
  List<ProblemExample> get examples {
    if (_examples is EqualUnmodifiableListView) return _examples;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_examples);
  }

  @override
  String toString() {
    return 'Problem(id: $id, title: $title, url: $url, difficulty: $difficulty, category: $category, hints: $hints, description: $description, examples: $examples)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProblemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(other._hints, _hints) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._examples, _examples));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    url,
    difficulty,
    category,
    const DeepCollectionEquality().hash(_hints),
    description,
    const DeepCollectionEquality().hash(_examples),
  );

  /// Create a copy of Problem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProblemImplCopyWith<_$ProblemImpl> get copyWith =>
      __$$ProblemImplCopyWithImpl<_$ProblemImpl>(this, _$identity);
}

abstract class _Problem implements Problem {
  const factory _Problem({
    required final String id,
    required final String title,
    required final String url,
    required final Difficulty difficulty,
    required final String category,
    final List<String> hints,
    final String? description,
    final List<ProblemExample> examples,
  }) = _$ProblemImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  String get url;
  @override
  Difficulty get difficulty;
  @override
  String get category;
  @override
  List<String> get hints;
  @override
  String? get description;
  @override
  List<ProblemExample> get examples;

  /// Create a copy of Problem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProblemImplCopyWith<_$ProblemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
