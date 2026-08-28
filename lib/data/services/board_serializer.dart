import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';

/// A machine-readable account of what is on the board, plus counts the UI can
/// show the user so they know what the AI could actually see.
class BoardDescription {
  final String text;
  final int noteCount;
  final int shapeCount;
  final int connectorCount;
  final int iconCount;
  final int freehandCount;

  const BoardDescription({
    required this.text,
    required this.noteCount,
    required this.shapeCount,
    required this.connectorCount,
    required this.iconCount,
    required this.freehandCount,
  });

  bool get isEmpty =>
      noteCount == 0 &&
      shapeCount == 0 &&
      connectorCount == 0 &&
      iconCount == 0 &&
      freehandCount == 0;

  /// True when the board has ink on it but nothing was recognised as text or a
  /// shape. The AI is close to blind in this case, and the UI says so.
  bool get isUnrecognised =>
      noteCount == 0 && shapeCount == 0 && freehandCount > 0;

  /// "3 notes · 2 shapes · 1 arrow" — shown next to each AI reply.
  String get chipLabel {
    if (isEmpty) return 'empty board';
    final parts = <String>[];
    if (noteCount > 0) {
      parts.add('$noteCount ${noteCount == 1 ? "note" : "notes"}');
    }
    if (shapeCount > 0) {
      parts.add('$shapeCount ${shapeCount == 1 ? "shape" : "shapes"}');
    }
    if (connectorCount > 0) {
      parts.add('$connectorCount ${connectorCount == 1 ? "arrow" : "arrows"}');
    }
    if (iconCount > 0) {
      parts.add('$iconCount ${iconCount == 1 ? "icon" : "icons"}');
    }
    if (freehandCount > 0) {
      parts.add(
        '$freehandCount unread sketch${freehandCount == 1 ? "" : "es"}',
      );
    }
    return parts.join(' · ');
  }
}

/// Converts strokes into a spatial text description for the language model.
///
/// The app already recognises handwriting into text and freehand into shapes,
/// but that structured data was never sent to the AI — only a screenshot was,
/// and a small on-device model reads handwriting from pixels poorly. Describing
/// the board in words is what lets it answer about what is actually there.
class BoardSerializer {
  /// Strokes closer than this to a connector endpoint count as connected.
  static const double _connectorSnapDistance = 60.0;

  /// Rows within this many units are treated as the same line for reading order.
  static const double _rowBandHeight = 48.0;

  static const int _maxNotes = 24;
  static const int _maxShapes = 20;
  static const int _maxNoteChars = 240;

  static Rect boundsOf(Stroke stroke) {
    if (stroke.points.isEmpty) return Rect.zero;
    var minX = stroke.points.first.dx;
    var maxX = minX;
    var minY = stroke.points.first.dy;
    var maxY = minY;
    for (final p in stroke.points) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static bool _isShape(StrokeType type) => const {
    StrokeType.circle,
    StrokeType.rectangle,
    StrokeType.triangle,
    StrokeType.diamond,
  }.contains(type);

  static String _round(double v) => v.round().toString();

  static String _truncate(String value, int max) {
    final collapsed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= max) return collapsed;
    return '${collapsed.substring(0, max)}…';
  }

  /// Labels shapes A, B, C… so connectors can refer to them by name.
  static String _shapeLabel(int index) {
    if (index < 26) return String.fromCharCode(65 + index);
    return 'S${index + 1}';
  }

  static BoardDescription describe(List<Stroke> strokes) {
    final notes = <({Stroke stroke, Rect bounds})>[];
    final shapes = <({Stroke stroke, Rect bounds})>[];
    final connectors = <({Stroke stroke, Rect bounds})>[];
    final icons = <({Stroke stroke, Rect bounds})>[];
    final freehand = <({Stroke stroke, Rect bounds})>[];

    for (final stroke in strokes) {
      if (stroke.isEraser || stroke.points.isEmpty) continue;
      final entry = (stroke: stroke, bounds: boundsOf(stroke));

      switch (stroke.type) {
        case StrokeType.text:
          if ((stroke.text ?? '').trim().isEmpty) continue;
          notes.add(entry);
        case StrokeType.connector:
          connectors.add(entry);
        case StrokeType.icon:
          icons.add(entry);
        case StrokeType.pen:
          freehand.add(entry);
        default:
          if (_isShape(stroke.type)) {
            shapes.add(entry);
          } else {
            freehand.add(entry);
          }
      }
    }

    final description = _render(
      notes: notes,
      shapes: shapes,
      connectors: connectors,
      icons: icons,
      freehand: freehand,
    );

    return BoardDescription(
      text: description,
      noteCount: notes.length,
      shapeCount: shapes.length,
      connectorCount: connectors.length,
      iconCount: icons.length,
      freehandCount: freehand.length,
    );
  }

  /// Sorts into human reading order: banded by row, then left to right.
  static List<T> _readingOrder<T extends ({Stroke stroke, Rect bounds})>(
    List<T> items,
  ) {
    final sorted = List<T>.from(items);
    sorted.sort((a, b) {
      final bandA = (a.bounds.top / _rowBandHeight).floor();
      final bandB = (b.bounds.top / _rowBandHeight).floor();
      if (bandA != bandB) return bandA.compareTo(bandB);
      return a.bounds.left.compareTo(b.bounds.left);
    });
    return sorted;
  }

  static String _render({
    required List<({Stroke stroke, Rect bounds})> notes,
    required List<({Stroke stroke, Rect bounds})> shapes,
    required List<({Stroke stroke, Rect bounds})> connectors,
    required List<({Stroke stroke, Rect bounds})> icons,
    required List<({Stroke stroke, Rect bounds})> freehand,
  }) {
    final total =
        notes.length +
        shapes.length +
        connectors.length +
        icons.length +
        freehand.length;

    if (total == 0) {
      return 'THE BOARD IS EMPTY. The student has not drawn or written '
          'anything yet.';
    }

    final buffer = StringBuffer();
    buffer.writeln('WHAT IS ON THE BOARD (transcribed from the strokes):');

    final orderedNotes = _readingOrder(notes);
    if (orderedNotes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Written notes, in reading order:');
      for (final (i, note) in orderedNotes.take(_maxNotes).indexed) {
        final text = _truncate(note.stroke.text ?? '', _maxNoteChars);
        final x = _round(note.bounds.left);
        final y = _round(note.bounds.top);
        buffer.writeln('  ${i + 1}. (at $x,$y) "$text"');
      }
      if (orderedNotes.length > _maxNotes) {
        buffer.writeln('  …and ${orderedNotes.length - _maxNotes} more notes.');
      }
    }

    final orderedShapes = _readingOrder(shapes);
    final labels = <Stroke, String>{};
    if (orderedShapes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Shapes drawn:');
      for (final (i, shape) in orderedShapes.take(_maxShapes).indexed) {
        final label = _shapeLabel(i);
        labels[shape.stroke] = label;
        final b = shape.bounds;
        buffer.writeln(
          '  $label. ${shape.stroke.type.name} at (${_round(b.left)},'
          '${_round(b.top)}) size ${_round(b.width)}x${_round(b.height)}',
        );
      }
      if (orderedShapes.length > _maxShapes) {
        buffer.writeln('  …and ${orderedShapes.length - _maxShapes} more.');
      }
    }

    if (connectors.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Arrows / connections:');
      for (final connector in connectors) {
        final points = connector.stroke.points;
        final from = points.first;
        final to = points.last;
        final fromLabel = _nearestLabel(from, orderedShapes, labels);
        final toLabel = _nearestLabel(to, orderedShapes, labels);

        if (fromLabel != null && toLabel != null) {
          buffer.writeln('  - $fromLabel -> $toLabel');
        } else {
          buffer.writeln(
            '  - line from (${_round(from.dx)},${_round(from.dy)}) '
            'to (${_round(to.dx)},${_round(to.dy)})',
          );
        }
      }
    }

    if (icons.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Diagram icons placed: ${icons.length}');
    }

    if (freehand.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        'Freehand sketches not recognised as text or shapes: '
        '${freehand.length}. Their meaning is only visible in the image.',
      );
    }

    if (notes.isEmpty && shapes.isEmpty) {
      buffer.writeln();
      buffer.writeln(
        'IMPORTANT: nothing on this board was recognised as text or a shape, '
        'so you may be misreading it. If you cannot tell what the student '
        'means, ask them to turn on handwriting recognition or type their '
        'note, instead of guessing.',
      );
    }

    return buffer.toString().trimRight();
  }

  static String? _nearestLabel(
    Offset point,
    List<({Stroke stroke, Rect bounds})> shapes,
    Map<Stroke, String> labels,
  ) {
    String? best;
    var bestDistance = _connectorSnapDistance;

    for (final shape in shapes) {
      final label = labels[shape.stroke];
      if (label == null) continue;

      final center = shape.bounds.center;
      final distance = shape.bounds.contains(point)
          ? 0.0
          : (point - center).distance -
                (math.max(shape.bounds.width, shape.bounds.height) / 2);

      if (distance <= bestDistance) {
        bestDistance = distance;
        best = label;
      }
    }
    return best;
  }
}
