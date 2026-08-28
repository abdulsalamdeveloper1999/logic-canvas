import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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

    // Retrying after a failure must not stack a second listener on the shared
    // progress stream, and must not leave the previous error on screen.
    await _progressSub?.cancel();
    _progressSub = null;

    emit(
      GemmaState(
        status: GemmaStatus.downloading,
        downloadProgress: 0.0,
        chatHistory: state.chatHistory,
      ),
    );

    _progressSub = _gemmaService.downloadProgress.listen((progress) {
      if (isClosed) return;
      emit(state.copyWith(downloadProgress: progress));
    });

    try {
      await _gemmaService.installModel();
      if (isClosed) return;
      emit(state.copyWith(status: GemmaStatus.ready, downloadProgress: 1.0));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: GemmaStatus.error,
          downloadProgress: 0.0,
          errorMessage: _readableDownloadError(e),
        ),
      );
    } finally {
      await _progressSub?.cancel();
      _progressSub = null;
    }
  }

  @visibleForTesting
  static String readableDownloadErrorForTest(Object error) =>
      _readableDownloadError(error);

  /// Turns plumbing exceptions into something a person can act on.
  static String _readableDownloadError(Object error) {
    final text = error.toString();
    final lower = text.toLowerCase();

    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('timed out') ||
        lower.contains('timeout')) {
      return 'The download was interrupted. Check your connection and try '
          'again — it will start over from the beginning.';
    }
    if (lower.contains('no space') ||
        lower.contains('storage') ||
        lower.contains('enospc')) {
      return 'There is not enough free space for the model (about 1.7 GB). '
          'Free some space and try again.';
    }
    if (lower.contains('http 4') || lower.contains('http 5')) {
      return 'The model could not be reached right now. Try again later.';
    }
    return 'The download failed and nothing was kept. Try again.\n\n$text';
  }

  @visibleForTesting
  static String readableInferenceErrorForTest(Object error) =>
      _readableInferenceError(error);

  /// The download path already spoke plainly; a failed reply used to dump the
  /// raw exception into the chat instead.
  static String _readableInferenceError(Object error) {
    final lower = error.toString().toLowerCase();

    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'The model took too long to answer. Close other apps and try '
          'again — if it keeps happening, delete and re-download the model in '
          'the sidebar.';
    }
    if (lower.contains('memory') || lower.contains('oom')) {
      return 'The device ran out of memory for the model. Close other apps and '
          'try again.';
    }
    if (lower.contains('not installed') ||
        lower.contains('no such file') ||
        lower.contains('cannot find')) {
      return 'The AI model is missing from this device. Download it again in '
          'the sidebar.';
    }
    return 'The AI could not finish that answer. Try asking again, with a '
        'shorter question if it keeps failing.';
  }

  /// Removes the downloaded model from the device, freeing the disk space.
  Future<void> deleteModel() async {
    await _gemmaService.deleteDownloadedModel();
    if (isClosed) return;
    emit(GemmaState(status: GemmaStatus.idle, chatHistory: state.chatHistory));
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
      emit(
        state.copyWith(aiLoading: false, aiError: _readableInferenceError(e)),
      );
    }
  }

  /// Drops the model's memory of the conversation without clearing what the
  /// user can see.
  ///
  /// Called when the board — and so the problem — changes. The service keeps
  /// its own rolling history and feeds it into every prompt, so without this a
  /// Two Sum discussion was still being sent as context for a graph problem.
  void resetConversationContext() {
    _gemmaService.clearHistory();
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
    // Free the loaded model, but leave the shared service usable. Fully
    // disposing it here closed the singleton's progress stream for the whole
    // app, which silently broke every later model download.
    _gemmaService.releaseResources();
    return super.close();
  }
}
