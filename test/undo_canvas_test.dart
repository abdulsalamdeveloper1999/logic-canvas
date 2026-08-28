import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:logic_canvas/core/injection.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/widgets/whiteboard_painter.dart';
import 'package:logic_canvas/presentation/widgets/whiteboard_view.dart';

/// What the canvas is actually painting: every [WhiteboardPainter] in the
/// tree, so the committed layer and the live overlay can both be checked. A
/// stroke that is gone from state but still on one of these is exactly what
/// "undo does nothing" looks like on screen.
List<WhiteboardPainter> paintersOf(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((c) => c.painter)
      .whereType<WhiteboardPainter>()
      .toList();
}

Stroke penStroke(int seed) => Stroke(
  points: [Offset(seed.toDouble(), seed.toDouble())],
  color: Colors.white,
  strokeWidth: 3,
);

Future<void> drawOneStroke(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    const Offset(200, 300),
    kind: PointerDeviceKind.stylus,
  );
  for (var i = 1; i <= 10; i++) {
    await gesture.moveTo(Offset(200 + i * 10.0, 300 + i * 5.0));
    await tester.pump(const Duration(milliseconds: 8));
  }
  await gesture.up();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('undo_canvas_');
    Hive.init(dir.path);
    await Hive.openBox<bool>('progress');
    await Hive.openBox(DrawingCubit.boxName);
    await Hive.openBox('settings');
    configureDependencies();
  });

  tearDownAll(() async {
    await Hive.close();
    await getIt.reset();
  });

  Future<DrawingCubit> pumpBoard(WidgetTester tester) async {
    final drawing = getIt<DrawingCubit>();
    final settings = getIt<SettingsCubit>();
    final entitlements = getIt<EntitlementsCubit>();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DrawingCubit>.value(value: drawing),
          BlocProvider<SettingsCubit>.value(value: settings),
          BlocProvider<EntitlementsCubit>.value(value: entitlements),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(child: WhiteboardView()),
                Positioned(
                  top: 0,
                  right: 0,
                  child: ElevatedButton(
                    onPressed: drawing.undo,
                    child: const Text('undo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return drawing;
  }

  testWidgets('undo takes the stroke off the canvas, not just out of state', (
    tester,
  ) async {
    final drawing = await pumpBoard(tester);

    await drawOneStroke(tester);
    expect(drawing.activeStrokes.length, 1, reason: 'the stroke committed');

    await tester.tap(find.text('undo'));
    await tester.pump();

    expect(drawing.activeStrokes, isEmpty);
    expect(
      paintersOf(
        tester,
      ).every((p) => p.strokes.isEmpty && p.activeStroke == null),
      isTrue,
      reason: 'the undone stroke is still being painted',
    );

    // close() cancels the debounced save timer, which the fake clock would
    // otherwise still see pending when the tree is torn down.
    await drawing.close();
  });

  test('a batch of strokes undoes and redoes as one action', () async {
    final drawing = getIt<DrawingCubit>();
    final batch = [penStroke(1), penStroke(2), penStroke(3)];

    drawing.addStroke(penStroke(0));
    drawing.addStrokes(batch);
    expect(drawing.activeStrokes.length, 4);

    // One press takes the whole batch back, not one paragraph of it.
    drawing.undo();
    expect(drawing.activeStrokes.length, 1);

    drawing.redo();
    expect(drawing.activeStrokes.length, 4);

    // And a stroke drawn afterwards still undoes on its own first.
    drawing.addStroke(penStroke(9));
    drawing.undo();
    expect(drawing.activeStrokes.length, 4);
    drawing.undo();
    expect(drawing.activeStrokes.length, 1);

    await drawing.close();
  });

  test('a batch of strokes undoes and redoes as one action', () async {
    final drawing = getIt<DrawingCubit>();
    final batch = [penStroke(1), penStroke(2), penStroke(3)];

    drawing.addStroke(penStroke(0));
    drawing.addStrokes(batch);
    expect(drawing.activeStrokes.length, 4);

    // One press takes the whole batch back, not one paragraph of it.
    drawing.undo();
    expect(drawing.activeStrokes.length, 1);

    drawing.redo();
    expect(drawing.activeStrokes.length, 4);

    // A stroke drawn afterwards still undoes on its own first.
    drawing.addStroke(penStroke(9));
    drawing.undo();
    expect(drawing.activeStrokes.length, 4);
    drawing.undo();
    expect(drawing.activeStrokes.length, 1);

    await drawing.close();
  });

  testWidgets('repeated undo keeps walking back through a busy board', (
    tester,
  ) async {
    final drawing = await pumpBoard(tester);
    for (var i = 0; i < 54; i++) {
      drawing.addStroke(penStroke(i));
    }
    await tester.pump();
    expect(drawing.activeStrokes.length, 54);

    await drawOneStroke(tester);
    expect(drawing.activeStrokes.length, 55);

    // Three undos with nothing drawn in between. This is the reported bug:
    // each press logged the same starting count, as if the stroke came back.
    for (final expected in [54, 53, 52]) {
      await tester.tap(find.text('undo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        drawing.activeStrokes.length,
        expected,
        reason: 'a stroke came back after undo',
      );
    }

    final painted = paintersOf(tester);
    expect(
      painted.first.strokes.length,
      52,
      reason: 'the canvas is painting a different board than the state holds',
    );

    await drawing.close();
  });
}
