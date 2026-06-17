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

const ModelType _kModelType = ModelType.gemma4;

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

  Future<void> init() async {
    final box = await Hive.openBox(_kBoxName);
    final installed = box.get(_kInstalledKey, defaultValue: false) as bool;
    final installedModelUrl = box.get(_kInstalledModelUrlKey) as String?;
    _isInstalled = installed && installedModelUrl == _kModelUrl;
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
        _progressController.add(progress / 100.0);
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

  Future<void> markDeleted() async {
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
    if (_history.isNotEmpty) {
      promptBuffer.writeln("--- Previous Conversation Context ---");
      for (final msg in _history) {
        final role = msg.isUser ? "User" : "AI";
        promptBuffer.writeln("$role: ${msg.text}");
      }
      promptBuffer.writeln("--- End Previous Context ---\n");
      promptBuffer.writeln("Current Request:");
    }
    promptBuffer.write(userMessage);

    final String finalQuery = promptBuffer.toString();

    final message = imageBytes != null
        ? Message.withImage(text: finalQuery, imageBytes: imageBytes, isUser: true)
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

      // Save context
      _history.add(Message.text(text: userMessage, isUser: true));
      _history.add(Message.text(text: fullResponseBuffer.toString(), isUser: false));

    } catch (e, stackTrace) {
      _llmLog('🧠 GemmaService.generateResponseStream: ERROR $e');
      _llmLog('🧠 GemmaService.generateResponseStream: STACK $stackTrace');
      rethrow;
    } finally {
      await model.close();
      _llmLog('🧠 GemmaService.generateResponseStream: model closed');
    }

    _llmLog('🧠 GemmaService.generateResponseStream: done');
  }

  Future<dynamic> _loadActiveModel() {
    _llmLog('🧠 GemmaService._loadActiveModel: loading active model');
    return FlutterGemma.getActiveModel(
      maxTokens: 2048,
      supportImage: true,
    ).timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        _llmLog('🧠 GemmaService._loadActiveModel: TIMEOUT after 2 minutes');
        throw TimeoutException(
          'Timed out loading the local AI model. Delete and re-download the '
          'model from Settings, then try again.',
        );
      },
    );
  }

  void dispose() {
    _progressController.close();
  }
}
