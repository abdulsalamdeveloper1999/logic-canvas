import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:logic_canvas/core/injection.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/gemma/gemma_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/widgets/board_panel.dart';

/// The drawer used to be four tabs (My Boards / Learn / Templates / Settings)
/// with everything at maximum visual emphasis — these tests pin the
/// redesign down: two tabs, settings behind a gear rather than competing for
/// tab-bar space, and Library merging what were separate Learn/Templates
/// tabs behind one search.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('board_panel_test_');
    Hive.init(dir.path);
    await Hive.openBox<bool>('progress');
    await Hive.openBox(DrawingCubit.boxName);
    await Hive.openBox('settings');
    configureDependencies();
  });

  tearDownAll(() async {
    await getIt.reset();
  });

  // DrawingCubit is registered as a factory, so getIt<DrawingCubit>() hands
  // out a fresh instance on every call. Each test grabs its own instance once
  // and reuses it for both the panel and its own assertions, rather than
  // calling getIt again and silently asserting on a second, unrelated cubit.
  Future<DrawingCubit> pumpPanel(WidgetTester tester) async {
    final drawing = getIt<DrawingCubit>();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DrawingCubit>.value(value: drawing),
          BlocProvider<SettingsCubit>.value(value: getIt<SettingsCubit>()),
          BlocProvider<GemmaCubit>.value(value: getIt<GemmaCubit>()),
        ],
        child: MaterialApp(
          home: Scaffold(body: SizedBox(width: 320, child: BoardPanel())),
        ),
      ),
    );
    await tester.pump();
    return drawing;
  }

  testWidgets('the drawer has exactly two tabs, not four', (tester) async {
    await pumpPanel(tester);

    expect(find.byType(Tab), findsNWidgets(2));
    expect(find.text('Boards'), findsWidgets);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Templates'), findsNothing);
    expect(find.text('Learn'), findsNothing);
  });

  testWidgets('settings lives behind the gear icon, not a tab', (tester) async {
    await pumpPanel(tester);

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // The sheet opened with settings content, not a fourth tab.
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('iCloud sync'), findsOneWidget);

    // 'Appearance' is further down the sheet's list and not laid out until
    // scrolled into view.
    await tester.scrollUntilVisible(
      find.text('Appearance'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Appearance'), findsOneWidget);

    // Close it so it doesn't leak a pending route into the next test.
    Navigator.of(tester.element(find.text('Settings'))).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('Library has one search box, not one per former tab', (
    tester,
  ) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Patterns'), findsWidgets);
    expect(find.text('Problems'), findsWidgets);
  });

  testWidgets('a new board can be created from the flat Boards row', (
    tester,
  ) async {
    final drawing = await pumpPanel(tester);
    final before = drawing.state.boardIds.length;

    await tester.tap(find.text('New board'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Redesign check');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(drawing.state.boardIds.length, before + 1);
    expect(drawing.state.boardIds, contains('Redesign check'));

    await drawing.close();
  });
}
