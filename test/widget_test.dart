// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:hive/hive.dart';

import 'package:logic_canvas/core/injection.dart';
import 'package:logic_canvas/main.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('logic_canvas_test_');
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

  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LogicCanvasApp());
    await tester.pumpAndSettle();

    expect(find.byType(LogicCanvasApp), findsOneWidget);
  });
}
