import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as ml;
import 'package:injectable/injectable.dart';
import '../../domain/entities/stroke.dart';
import 'shape_detection_service.dart';

@lazySingleton
class MLShapeService {
  // Use the universal 'shape' model code for ML Kit
  static const String _modelCode = 'zxx-Zxxx-x-shape';

  // SAFETY: On some iOS versions, ML Kit shape detection crashes the native side.
  // We set this to true to force fallback to manual heuristics.
  static bool _forceManualOnly = true;

  ml.DigitalInkRecognizer? _recognizer;
  final ml.DigitalInkRecognizerModelManager _modelManager =
      ml.DigitalInkRecognizerModelManager();
  bool _isInitializing = false;

  Future<void> _ensureInitialized() async {
    if (_forceManualOnly) {
      return;
    }

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
        debugPrint('Downloading ML Kit shape model ($_modelCode)...');
        await _modelManager
            .downloadModel(_modelCode)
            .timeout(
              const Duration(seconds: 40),
              onTimeout: () => throw Exception('Model download timed out'),
            );

        final verifyDownload = await _modelManager.isModelDownloaded(
          _modelCode,
        );
        if (!verifyDownload) {
          throw Exception('Model download failed verification');
        }
      }

      if (_recognizer == null) {
        _recognizer = ml.DigitalInkRecognizer(languageCode: _modelCode);
        debugPrint(
          'ML Kit shape recognizer initialized successfully with code: $_modelCode',
        );
      }
    } catch (e) {
      debugPrint('CRITICAL: Failed to initialize ML Kit shape recognizer: $e');
      _recognizer = null;
      _forceManualOnly = true;
    } finally {
      _isInitializing = false;
    }
  }

  Future<StrokeType> detectShape(List<Offset> points) async {
    if (points.isEmpty) {
      return StrokeType.pen;
    }

    // FAST PATH: Check manual heuristics first for simple shapes
    final manualType = ShapeDetectionService.detectShape(points);
    if (manualType != StrokeType.pen) {
      debugPrint('ML Shape: Using manual fallback detection: $manualType');
      return manualType;
    }

    if (_forceManualOnly) {
      return StrokeType.pen;
    }

    // Require at least 10 points for ML Kit to be accurate
    if (points.length < 10) {
      return StrokeType.pen;
    }

    try {
      await _ensureInitialized();

      if (_recognizer == null || _forceManualOnly) {
        return StrokeType.pen;
      }

      final ink = ml.Ink();
      final stroke = ml.Stroke();

      for (int i = 0; i < points.length; i++) {
        stroke.points.add(
          ml.StrokePoint(x: points[i].dx, y: points[i].dy, t: i * 10),
        );
      }
      ink.strokes.add(stroke);

      // CRITICAL: Catch native exception if possible (it's not always possible in Dart)
      final candidates = await _recognizer!.recognize(ink);
      if (candidates.isNotEmpty) {
        final topMatch = candidates.first.text.toLowerCase();
        debugPrint(
          'ML SHAPE: Top candidate: "$topMatch" (Score: ${candidates.first.score})',
        );

        if (topMatch.contains('circle')) {
          return StrokeType.circle;
        }
        if (topMatch.contains('square') || topMatch.contains('rectangle')) {
          return StrokeType.rectangle;
        }
        if (topMatch.contains('triangle')) {
          return StrokeType.triangle;
        }
        if (topMatch.contains('diamond') || topMatch.contains('rhombus')) {
          return StrokeType.diamond;
        }
      }
    } catch (e) {
      debugPrint('ML Shape recognition error: $e');
    }

    return StrokeType.pen;
  }

  void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}
