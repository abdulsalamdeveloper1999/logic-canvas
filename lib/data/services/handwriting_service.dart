import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart' as ml;
import 'package:injectable/injectable.dart';

@lazySingleton
class HandwritingRecognitionService {
  static const String _modelCode = 'en-US';
  
  ml.DigitalInkRecognizer? _recognizer;
  final ml.DigitalInkRecognizerModelManager _modelManager = ml.DigitalInkRecognizerModelManager();
  bool _isInitializing = false;

  Future<void> _ensureInitialized() async {
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;
    try {
      if (_modelCode.isEmpty) throw Exception('Model code is empty');

      final isDownloaded = await _modelManager.isModelDownloaded(_modelCode);
      if (!isDownloaded) {
        debugPrint('Downloading ML Kit handwriting model ($_modelCode)...');
        await _modelManager.downloadModel(_modelCode).timeout(
          const Duration(seconds: 40),
          onTimeout: () => throw Exception('Model download timed out'),
        );

        final verifyDownload = await _modelManager.isModelDownloaded(_modelCode);
        if (!verifyDownload) throw Exception('Model download failed verification');
      }
      
      if (_recognizer == null) {
        _recognizer = ml.DigitalInkRecognizer(languageCode: _modelCode);
        debugPrint('ML Kit handwriting recognizer initialized successfully.');
      }
    } catch (e) {
      debugPrint('CRITICAL: Failed to initialize ML Kit handwriting recognizer: $e');
      _recognizer = null;
    } finally {
      _isInitializing = false;
    }
  }

  Future<String?> recognize(List<List<Offset>> multiStrokes) async {
    if (multiStrokes.isEmpty) return null;
    
    try {
      await _ensureInitialized();

      if (_recognizer == null) {
        return null;
      }

      final ink = ml.Ink();
      
      int totalPoints = 0;
      for (final strokePoints in multiStrokes) {
        final stroke = ml.Stroke();
        for (final point in strokePoints) {
          stroke.points.add(ml.StrokePoint(
            x: point.dx,
            y: point.dy,
            t: totalPoints * 10, // Simulated relative timestamps
          ));
          totalPoints++;
        }
        ink.strokes.add(stroke);
      }

      final candidates = await _recognizer!.recognize(ink);
      if (candidates.isNotEmpty) {
        return candidates.first.text;
      }
    } catch (e) {
      debugPrint('Handwriting recognition error: $e');
    }
    return null;
  }

  void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}
