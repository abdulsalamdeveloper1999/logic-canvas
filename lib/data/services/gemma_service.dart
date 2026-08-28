import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:injectable/injectable.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String _kBoxName = 'settings';
const String _kInstalledKey = 'gemma_installed';
const String _kInstalledModelUrlKey = 'gemma_installed_model_url';

const String _kModelUrl =
    'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm';

/// flutter_gemma identifies an installed model by its filename, which is what
/// both the install check and the uninstall call need.
const String _kModelFileName = 'gemma-4-E4B-it.litertlm';

const ModelType _kModelType = ModelType.gemma4;

/// Context budget. The old settings let history alone consume 6,000 characters
/// out of a 2,048-token window that also had to hold the system prompt, an
/// image, and the answer — so replies were being squeezed out. The window is
/// now larger, and history shrinks further when an image is attached.
const int _kMaxTokens = 4096;
const int _kMaxContextMessages = 6;
const int _kMaxContextCharacters = 2400;
const int _kMaxContextCharactersWithImage = 1200;

void _llmLog(String message) {
  debugPrintSynchronously(message);
  developer.log(message, name: 'LogicCanvasLLM');
}

@lazySingleton
class GemmaService {
  final _progressController = StreamController<double>.broadcast();
  Stream<double> get downloadProgress => _progressController.stream;

  bool _isInstalled = false;
  bool get isInstalled => _isInstalled;

  // Short rolling history buffer for conversational context
  final List<Message> _history = [];

  /// Held open between messages so each reply does not pay the model-load cost.
  dynamic _activeModel;

  /// True once the download has finished and the file is really on disk.
  ///
  /// The Hive flag alone is not enough: iOS can evict a 1.7 GB file under
  /// storage pressure, and a half-finished install can leave the flag set with
  /// no model behind it. Both cases used to surface as a confusing failure at
  /// inference time instead of an honest "not downloaded".
  Future<void> init() async {
    final box = await Hive.openBox(_kBoxName);
    final installed = box.get(_kInstalledKey, defaultValue: false) as bool;
    final installedModelUrl = box.get(_kInstalledModelUrlKey) as String?;
    final flaggedInstalled = installed && installedModelUrl == _kModelUrl;

    if (!flaggedInstalled) {
      _isInstalled = false;
      return;
    }

    try {
      final onDisk = await FlutterGemma.isModelInstalled(_kModelFileName);
      _isInstalled = onDisk;
      if (!onDisk) {
        _llmLog('🧠 GemmaService: flag said installed but the file is gone');
        await box.put(_kInstalledKey, false);
        await box.delete(_kInstalledModelUrlKey);
      }
    } catch (e) {
      // If the check itself fails, trust the flag rather than forcing a
      // needless 1.7 GB re-download.
      _llmLog('🧠 GemmaService: install check failed ($e), trusting the flag');
      _isInstalled = true;
    }
  }

  Future<void> installModel() async {
    try {
      await _validateModelUrl();

      await FlutterGemma.installModel(
        modelType: _kModelType,
        fileType: ModelFileType.litertlm,
      ).fromNetwork(_kModelUrl).withProgress((progress) {
        if (progress < 0 || progress > 100) {
          throw StateError('Model download failed with progress $progress');
        }
        // Never let a reporting problem abort a 1.7 GB download.
        if (!_progressController.isClosed) {
          _progressController.add(progress / 100.0);
        }
      }).install();

      final box = await Hive.openBox(_kBoxName);
      await box.put(_kInstalledKey, true);
      await box.put(_kInstalledModelUrlKey, _kModelUrl);
      _isInstalled = true;
    } catch (_) {
      await markDeleted();
      rethrow;
    }
  }

  Future<void> _validateModelUrl() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.headUrl(Uri.parse(_kModelUrl));
      final response = await request.close();
      final statusCode = response.statusCode;
      await response.drain<void>();

      if (statusCode >= 400) {
        throw HttpException(
          'Model URL returned HTTP $statusCode',
          uri: Uri.parse(_kModelUrl),
        );
      }
    } finally {
      client.close(force: true);
    }
  }

  /// Removes the downloaded model from disk and forgets it.
  ///
  /// [markDeleted] only ever cleared a flag, so "Delete" left the whole 1.7 GB
  /// on the device — and the next download fetched it all over again.
  Future<void> deleteDownloadedModel() async {
    await _releaseModel();
    try {
      await FlutterGemma.uninstallModel(_kModelFileName);
      _llmLog('🧠 GemmaService: model file removed');
    } catch (e) {
      // Nothing to remove, or the plugin could not find it. Clearing the flag
      // below still lets the user re-download.
      _llmLog('🧠 GemmaService: uninstall reported "$e"');
    }
    await markDeleted();
  }

  Future<void> markDeleted() async {
    await _releaseModel();
    final box = await Hive.openBox(_kBoxName);
    await box.put(_kInstalledKey, false);
    await box.delete(_kInstalledModelUrlKey);
    _isInstalled = false;
  }

  void clearHistory() {
    _history.clear();
  }

  Future<void> generateResponseStream({
    required String systemPrompt,
    required String userMessage,
    required void Function(String token) onThinkingToken,
    required void Function(String token) onResponseToken,
    Uint8List? imageBytes,
    bool includeHistory = true,
  }) async {
    _llmLog('🧠 GemmaService.generateResponseStream: start');

    final model = await _loadActiveModel();
    _llmLog('🧠 GemmaService.generateResponseStream: active model acquired');

    final chat = await model.createChat(
      systemInstruction: systemPrompt,
      isThinking: false,
    );
    _llmLog('🧠 GemmaService.generateResponseStream: chat created');

    // Flatten history into the user message to prevent native LiteRT-LM segfaults
    // from multiple addQueryChunk calls or 'isUser: false' chunks.
    final promptBuffer = StringBuffer();
    final contextHistory = includeHistory
        ? _trimmedHistoryForPrompt(hasImage: imageBytes != null)
        : const <Message>[];
    if (contextHistory.isNotEmpty) {
      promptBuffer.writeln("--- Previous Conversation Context ---");
      for (final msg in contextHistory) {
        final role = msg.isUser ? "User" : "AI";
        promptBuffer.writeln("$role: ${msg.text}");
      }
      promptBuffer.writeln("--- End Previous Context ---\n");
      promptBuffer.writeln("Current Request:");
    }
    promptBuffer.write(userMessage);

    final String finalQuery = promptBuffer.toString();

    final message = imageBytes != null
        ? Message.withImage(
            text: finalQuery,
            imageBytes: imageBytes,
            isUser: true,
          )
        : Message.text(text: finalQuery, isUser: true);
    await chat.addQueryChunk(message);
    _llmLog('🧠 GemmaService.generateResponseStream: user chunk added');

    final fullResponseBuffer = StringBuffer();

    try {
      await for (final res in chat.generateChatResponseAsync()) {
        if (res is ThinkingResponse) {
          onThinkingToken(res.content);
        } else if (res is TextResponse) {
          fullResponseBuffer.write(res.token);
          onResponseToken(res.token);
        }
      }

      if (includeHistory) {
        _history.add(Message.text(text: userMessage, isUser: true));
        _history.add(
          Message.text(text: fullResponseBuffer.toString(), isUser: false),
        );
        _trimStoredHistory();
      }
    } catch (e, stackTrace) {
      _llmLog('🧠 GemmaService.generateResponseStream: ERROR $e');
      _llmLog('🧠 GemmaService.generateResponseStream: STACK $stackTrace');
      // A failed generation may have left the native session unusable, so drop
      // the cached model and reload it next time.
      await _releaseModel();
      rethrow;
    }

    _llmLog('🧠 GemmaService.generateResponseStream: done');
  }

  /// The loaded model is kept between messages. It used to be closed after
  /// every reply, which made the user pay the full model-load cost each time
  /// they asked anything.
  Future<dynamic> _loadActiveModel() async {
    final cached = _activeModel;
    if (cached != null) {
      _llmLog('🧠 GemmaService._loadActiveModel: reusing warm model');
      return cached;
    }

    _llmLog('🧠 GemmaService._loadActiveModel: loading active model');
    final model =
        await FlutterGemma.getActiveModel(
          maxTokens: _kMaxTokens,
          supportImage: true,
        ).timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            _llmLog(
              '🧠 GemmaService._loadActiveModel: TIMEOUT after 2 minutes',
            );
            throw TimeoutException(
              'Timed out loading the local AI model. Delete and re-download the '
              'model from Settings, then try again.',
            );
          },
        );

    _activeModel = model;
    return model;
  }

  Future<void> _releaseModel() async {
    final model = _activeModel;
    _activeModel = null;
    if (model == null) return;
    try {
      await model.close();
      _llmLog('🧠 GemmaService: model closed');
    } catch (e) {
      _llmLog('🧠 GemmaService: error closing model ($e)');
    }
  }

  List<Message> _trimmedHistoryForPrompt({bool hasImage = false}) {
    final characterBudget = hasImage
        ? _kMaxContextCharactersWithImage
        : _kMaxContextCharacters;

    var totalCharacters = 0;
    final kept = <Message>[];

    for (final message in _history.reversed) {
      final messageLength = message.text.length;
      if (kept.length >= _kMaxContextMessages ||
          totalCharacters + messageLength > characterBudget) {
        break;
      }
      kept.add(message);
      totalCharacters += messageLength;
    }

    return kept.reversed.toList();
  }

  void _trimStoredHistory() {
    final kept = _trimmedHistoryForPrompt();
    _history
      ..clear()
      ..addAll(kept);
  }

  /// Frees the loaded model but keeps the service usable.
  ///
  /// This is a lazySingleton shared by every [GemmaCubit]. Closing the progress
  /// stream here would kill it for the whole app: once closed it can never
  /// reopen, so the next download would report no progress and — because the
  /// old code threw when adding to a closed controller — fail outright.
  Future<void> releaseResources() async {
    await _releaseModel();
  }

  /// Only for application teardown, when nothing will use this service again.
  Future<void> disposeSingleton() async {
    await _releaseModel();
    await _progressController.close();
  }
}
