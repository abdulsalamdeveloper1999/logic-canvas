import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logic_canvas/data/services/gemma_service.dart';
import 'gemma_state.dart';

const int _kMaxVisibleChatMessages = 12;

@injectable
class GemmaCubit extends Cubit<GemmaState> {
  final GemmaService _gemmaService;
  StreamSubscription<double>? _progressSub;

  GemmaCubit(this._gemmaService) : super(const GemmaState());

  Future<void> init() async {
    await _gemmaService.init();
    if (_gemmaService.isInstalled) {
      emit(state.copyWith(status: GemmaStatus.ready));
    }
  }

  Future<void> checkAndDownload() async {
    if (state.status == GemmaStatus.downloading ||
        state.status == GemmaStatus.ready) {
      return;
    }

    if (_gemmaService.isInstalled) {
      emit(state.copyWith(status: GemmaStatus.ready));
      return;
    }

    emit(
      state.copyWith(status: GemmaStatus.downloading, downloadProgress: 0.0),
    );

    _progressSub = _gemmaService.downloadProgress.listen((progress) {
      emit(state.copyWith(downloadProgress: progress));
    });

    try {
      await _gemmaService.installModel();
      emit(state.copyWith(status: GemmaStatus.ready, downloadProgress: 1.0));
    } catch (e) {
      emit(
        state.copyWith(status: GemmaStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> deleteModel() async {
    await _gemmaService.markDeleted();
    emit(const GemmaState(status: GemmaStatus.idle));
  }

  Future<void> generateAiResponse({
    required String systemPrompt,
    required String userMessage,
    Uint8List? imageBytes,
    bool includeHistory = true,
  }) async {
    if (state.status != GemmaStatus.ready) {
      emit(
        state.copyWith(
          aiError: 'AI model not ready. Please download it first in Settings.',
        ),
      );
      return;
    }

    // Append user message to history
    final userMsg = UiChatMessage(text: userMessage, isUser: true);
    final updatedHistory = List<UiChatMessage>.from(state.chatHistory)
      ..add(userMsg);

    emit(
      state.copyWith(
        aiLoading: true,
        aiThinking: null,
        aiResponse: null,
        aiError: null,
        chatHistory: _trimVisibleChat(updatedHistory),
      ),
    );

    try {
      await _gemmaService.generateResponseStream(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
        imageBytes: imageBytes,
        includeHistory: includeHistory,
        onThinkingToken: (token) {
          emit(
            state.copyWith(
              aiThinking: _humanizeModelText((state.aiThinking ?? '') + token),
            ),
          );
        },
        onResponseToken: (token) {
          emit(
            state.copyWith(
              aiResponse: _humanizeModelText((state.aiResponse ?? '') + token),
            ),
          );
        },
      );
      // Append AI message to history
      final finalResponse = _humanizeModelText(state.aiResponse ?? '').trim();
      final aiMsg = UiChatMessage(text: finalResponse, isUser: false);
      final finalHistory = List<UiChatMessage>.from(state.chatHistory)
        ..add(aiMsg);

      emit(
        state.copyWith(
          aiLoading: false,
          aiResponse: null, // Clear active response so it moves to history
          chatHistory: _trimVisibleChat(finalHistory),
        ),
      );
    } catch (e) {
      emit(state.copyWith(aiLoading: false, aiError: e.toString()));
    }
  }

  void clearAiResponse() {
    _gemmaService.clearHistory();
    emit(
      state.copyWith(
        aiLoading: false,
        aiThinking: null,
        aiResponse: null,
        aiError: null,
        chatHistory: const [],
      ),
    );
  }

  String _humanizeModelText(String text) {
    return text
        .replaceAllMapped(RegExp(r'\$([^$]+)\$'), (match) {
          return _humanizeMath(match.group(1) ?? '');
        })
        .replaceAllMapped(RegExp(r'\\\((.*?)\\\)'), (match) {
          return _humanizeMath(match.group(1) ?? '');
        })
        .replaceAllMapped(RegExp(r'\\\[(.*?)\\\]', dotAll: true), (match) {
          return _humanizeMath(match.group(1) ?? '');
        })
        .replaceAll(r'\leq', '<=')
        .replaceAll(r'\le', '<=')
        .replaceAll(r'\geq', '>=')
        .replaceAll(r'\ge', '>=')
        .replaceAll(r'\neq', '!=')
        .replaceAll(r'\ne', '!=')
        .replaceAll(r'\lt', '<')
        .replaceAll(r'\gt', '>')
        .replaceAll(r'\times', '*')
        .replaceAll(r'\cdot', '*')
        .replaceAll(r'\rightarrow', '->')
        .replaceAll(r'\to', '->')
        .replaceAll(r'\log', 'log')
        .replaceAll(r'\n', '\n');
  }

  String _humanizeMath(String text) {
    return text
        .trim()
        .replaceAll(r'\leq', '<=')
        .replaceAll(r'\le', '<=')
        .replaceAll(r'\geq', '>=')
        .replaceAll(r'\ge', '>=')
        .replaceAll(r'\neq', '!=')
        .replaceAll(r'\ne', '!=')
        .replaceAll(r'\lt', '<')
        .replaceAll(r'\gt', '>')
        .replaceAll(r'\times', '*')
        .replaceAll(r'\cdot', '*')
        .replaceAll(r'\rightarrow', '->')
        .replaceAll(r'\to', '->')
        .replaceAll(r'\log', 'log');
  }

  List<UiChatMessage> _trimVisibleChat(List<UiChatMessage> messages) {
    if (messages.length <= _kMaxVisibleChatMessages) return messages;
    return messages.sublist(messages.length - _kMaxVisibleChatMessages);
  }

  @override
  Future<void> close() {
    _progressSub?.cancel();
    _gemmaService.dispose();
    return super.close();
  }
}
