import 'package:freezed_annotation/freezed_annotation.dart';

part 'gemma_state.freezed.dart';

class UiChatMessage {
  final String text;
  final bool isUser;
  
  const UiChatMessage({
    required this.text,
    required this.isUser,
  });
}

@freezed
class GemmaState with _$GemmaState {
  const factory GemmaState({
    @Default(GemmaStatus.idle) GemmaStatus status,
    @Default(0.0) double downloadProgress,
    String? errorMessage,
    @Default(false) bool aiLoading,
    String? aiThinking,
    String? aiResponse,
    String? aiError,
    @Default([]) List<UiChatMessage> chatHistory,
  }) = _GemmaState;
}

enum GemmaStatus { idle, downloading, ready, error }
