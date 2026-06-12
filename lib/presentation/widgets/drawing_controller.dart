import 'package:flutter/material.dart';

class Stroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });
}

enum BackgroundPattern { none, grid, lines }

class DrawingController extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];
  Color _currentColor = Colors.white;
  double _currentWidth = 3.0;
  bool _isEraser = false;
  BackgroundPattern _pattern = BackgroundPattern.grid;

  List<Stroke> get strokes => _strokes;
  Color get currentColor => _currentColor;
  double get currentWidth => _currentWidth;
  bool get isEraser => _isEraser;
  BackgroundPattern get pattern => _pattern;

  void setPattern(BackgroundPattern pattern) {
    _pattern = pattern;
    notifyListeners();
  }

  void startStroke(Offset point) {
    _strokes.add(
      Stroke(
        points: [point],
        color: _isEraser ? Colors.transparent : _currentColor,
        strokeWidth: _currentWidth,
        isEraser: _isEraser,
      ),
    );
    _redoStack.clear();
    notifyListeners();
  }

  void updateStroke(Offset point) {
    if (_strokes.isNotEmpty) {
      _strokes.last.points.add(point);
      notifyListeners();
    }
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _redoStack.add(_strokes.removeLast());
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _strokes.add(_redoStack.removeLast());
      notifyListeners();
    }
  }

  void clear() {
    _strokes.clear();
    _redoStack.clear();
    notifyListeners();
  }

  void setTool(bool isEraser) {
    _isEraser = isEraser;
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    _isEraser = false;
    notifyListeners();
  }

  void setWidth(double width) {
    _currentWidth = width;
    notifyListeners();
  }
}
