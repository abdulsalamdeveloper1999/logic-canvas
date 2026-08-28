import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logic_canvas/data/services/board_serializer.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';

Stroke note(String text, {double x = 0, double y = 0}) => Stroke(
  points: [Offset(x, y)],
  color: Colors.white,
  strokeWidth: 2,
  type: StrokeType.text,
  text: text,
);

Stroke shape(
  StrokeType type, {
  required double left,
  required double top,
  double width = 100,
  double height = 80,
}) => Stroke(
  points: [Offset(left, top), Offset(left + width, top + height)],
  color: Colors.white,
  strokeWidth: 2,
  type: type,
);

Stroke connector(Offset from, Offset to) => Stroke(
  points: [from, to],
  color: Colors.white,
  strokeWidth: 2,
  type: StrokeType.connector,
);

Stroke scribble({double x = 0, double y = 0}) => Stroke(
  points: [Offset(x, y), Offset(x + 5, y + 5), Offset(x + 10, y)],
  color: Colors.white,
  strokeWidth: 2,
);

void main() {
  group('BoardSerializer', () {
    test('says plainly when the board is empty', () {
      final result = BoardSerializer.describe(const []);

      expect(result.isEmpty, isTrue);
      expect(result.text, contains('THE BOARD IS EMPTY'));
      expect(result.chipLabel, 'empty board');
    });

    test('transcribes note text — the whole point of the fix', () {
      // Ask mode previously sent only a screenshot, so this text never
      // reached the model even though the app had already recognised it.
      final result = BoardSerializer.describe([
        note('use a hashmap to store seen values', x: 120, y: 100),
      ]);

      expect(result.text, contains('use a hashmap to store seen values'));
      expect(result.noteCount, 1);
      expect(result.chipLabel, '1 note');
    });

    test('orders notes top-to-bottom, then left-to-right', () {
      final result = BoardSerializer.describe([
        note('third', x: 100, y: 400),
        note('second', x: 300, y: 100),
        note('first', x: 100, y: 100),
      ]);

      final firstAt = result.text.indexOf('first');
      final secondAt = result.text.indexOf('second');
      final thirdAt = result.text.indexOf('third');

      expect(firstAt, lessThan(secondAt));
      expect(secondAt, lessThan(thirdAt));
    });

    test('includes each note position so the model can reason spatially', () {
      final result = BoardSerializer.describe([
        note('left branch', x: 120, y: 240),
      ]);

      expect(result.text, contains('(at 120,240)'));
    });

    test('labels shapes and resolves arrows between them', () {
      final result = BoardSerializer.describe([
        shape(StrokeType.rectangle, left: 100, top: 100),
        shape(StrokeType.circle, left: 400, top: 100),
        connector(const Offset(150, 140), const Offset(450, 140)),
      ]);

      expect(result.text, contains('A. rectangle at (100,100) size 100x80'));
      expect(result.text, contains('B. circle at (400,100) size 100x80'));
      expect(result.text, contains('A -> B'));
      expect(result.shapeCount, 2);
      expect(result.connectorCount, 1);
    });

    test('falls back to coordinates for an arrow joined to nothing', () {
      final result = BoardSerializer.describe([
        connector(const Offset(10, 10), const Offset(900, 900)),
      ]);

      expect(result.text, contains('line from (10,10) to (900,900)'));
    });

    test('warns when nothing was recognised, instead of bluffing', () {
      final result = BoardSerializer.describe([
        scribble(x: 10, y: 10),
        scribble(x: 40, y: 10),
      ]);

      expect(result.isUnrecognised, isTrue);
      expect(result.freehandCount, 2);
      expect(result.text, contains('nothing on this board was recognised'));
      expect(result.text, contains('ask them'));
      expect(result.chipLabel, contains('unread sketch'));
    });

    test('does not warn once there is recognised content', () {
      final result = BoardSerializer.describe([
        note('two pointers', x: 10, y: 10),
        scribble(x: 40, y: 90),
      ]);

      expect(result.isUnrecognised, isFalse);
      expect(
        result.text,
        isNot(contains('nothing on this board was recognised')),
      );
    });

    test('ignores eraser strokes and blank notes', () {
      final result = BoardSerializer.describe([
        note('   ', x: 10, y: 10),
        Stroke(
          points: const [Offset(0, 0), Offset(10, 10)],
          color: Colors.white,
          strokeWidth: 20,
          isEraser: true,
        ),
      ]);

      expect(result.isEmpty, isTrue);
    });

    test('collapses newlines and truncates a very long note', () {
      final long = List.generate(80, (i) => 'word$i').join(' ');
      final result = BoardSerializer.describe([
        note('line one\n\n   line two', x: 0, y: 0),
        note(long, x: 0, y: 200),
      ]);

      expect(result.text, contains('"line one line two"'));
      expect(result.text, contains('…'));
      // Every note stays on one line, so the reading-order list is parseable.
      final noteLines = result.text
          .split('\n')
          .where((l) => l.trimLeft().startsWith(RegExp(r'\d+\. \(at')));
      expect(noteLines.length, 2);
    });

    test('caps the note list rather than flooding the prompt', () {
      final many = List.generate(
        40,
        (i) => note('note number $i', x: 0, y: i * 60),
      );

      final result = BoardSerializer.describe(many);

      expect(result.noteCount, 40);
      expect(result.text, contains('more notes'));
      expect(result.text.length, lessThan(4000));
    });

    test('chipLabel reads as a plain-English summary', () {
      final result = BoardSerializer.describe([
        note('a', x: 0, y: 0),
        note('b', x: 0, y: 100),
        shape(StrokeType.circle, left: 0, top: 200),
        connector(const Offset(0, 0), const Offset(5, 5)),
      ]);

      expect(result.chipLabel, '2 notes · 1 shape · 1 arrow');
    });

    test('bounds are computed from every point, not just the first', () {
      final bounds = BoardSerializer.boundsOf(
        Stroke(
          points: const [Offset(50, 90), Offset(10, 200), Offset(300, 20)],
          color: Colors.white,
          strokeWidth: 1,
        ),
      );

      expect(bounds.left, 10);
      expect(bounds.top, 20);
      expect(bounds.right, 300);
      expect(bounds.bottom, 200);
    });
  });
}
