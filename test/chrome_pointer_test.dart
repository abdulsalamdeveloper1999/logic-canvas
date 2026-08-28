import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:logic_canvas/core/injection.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_cubit.dart';
import 'package:logic_canvas/presentation/cubits/gemma/gemma_cubit.dart';
import 'package:logic_canvas/presentation/cubits/progress/progress_cubit.dart';
import 'package:logic_canvas/presentation/cubits/selection/selection_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/pages/home/home_page.dart';

/// The bars floating over the board paint with shaders and backdrop filters,
/// neither of which claims a pointer hit. Without an explicit shield a tap that
/// lands on a bar but misses a button falls through to the canvas and commits a
/// one-point dot — invisible under the chrome, and enough to make undo look
/// broken, because the next undo press just removes that dot.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('chrome_pointer_');
    Hive.init(dir.path);
    await Hive.openBox<bool>('progress');
    await Hive.openBox(DrawingCubit.boxName);
    await Hive.openBox('settings');
    configureDependencies();
  });

  tearDownAll(() async {
    // Deliberately not closing Hive: a cubit built during these tests can have
    // a snapshot write parked behind the fake clock, and Hive.close() then
    // waits for a lock that is never released. The temp box goes away with the
    // directory anyway.
    await getIt.reset();
  });

  testWidgets('the AI button leads somewhere when the model is missing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final drawing = getIt<DrawingCubit>();
    final settings = getIt<SettingsCubit>();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DrawingCubit>.value(value: drawing),
          BlocProvider<SettingsCubit>.value(value: settings),
          BlocProvider<EntitlementsCubit>.value(
            value: getIt<EntitlementsCubit>(),
          ),
          BlocProvider<ProgressCubit>.value(value: getIt<ProgressCubit>()),
          BlocProvider<SelectionCubit>.value(value: getIt<SelectionCubit>()),
          BlocProvider<GemmaCubit>.value(value: getIt<GemmaCubit>()),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    // No model is installed in a test, so the assistant is unreachable. The
    // button has to say so and open the place the download lives, rather than
    // toggling the sidebar shut on whoever already had it open.
    expect(settings.state.showSidebar, isFalse);

    await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
    await tester.pump();

    expect(
      settings.state.showSidebar,
      isTrue,
      reason: 'the AI button did not open the sidebar holding the download',
    );

    // Tapping again must not close it back up.
    await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
    await tester.pump();
    expect(settings.state.showSidebar, isTrue);

    // Let the toasts time out so the binding sees no pending timer.
    await tester.pump(const Duration(seconds: 5));
    await drawing.close();
  });

  testWidgets('tapping the chrome never draws on the board', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final drawing = getIt<DrawingCubit>();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DrawingCubit>.value(value: drawing),
          BlocProvider<SettingsCubit>.value(value: getIt<SettingsCubit>()),
          BlocProvider<EntitlementsCubit>.value(
            value: getIt<EntitlementsCubit>(),
          ),
          BlocProvider<ProgressCubit>.value(value: getIt<ProgressCubit>()),
          BlocProvider<SelectionCubit>.value(value: getIt<SelectionCubit>()),
          BlocProvider<GemmaCubit>.value(value: getIt<GemmaCubit>()),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    // Inside the actions pill but on no button: its padding, just left of the
    // undo button. The pill has to claim this hit itself.
    final undoButton = find.ancestor(
      of: find.byIcon(Icons.undo_rounded),
      matching: find.byType(GlassIconButton),
    );
    final undoRect = tester.getRect(undoButton);
    await tester.tapAt(Offset(undoRect.left - 5, undoRect.center.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      drawing.activeStrokes,
      isEmpty,
      reason: 'a tap on the top bar pill drew a stray dot on the canvas',
    );

    // And the undo button itself must still work rather than being shielded.
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.undo_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      drawing.activeStrokes,
      isEmpty,
      reason: 'pressing undo drew a stray dot on the canvas',
    );

    // The two pills are separate and the board is exposed between them, which
    // is the point of splitting the bar: a tap in that gap belongs to the board.
    final brand = tester.getRect(find.text('LogicCanvas'));
    expect(
      undoRect.left - brand.right,
      greaterThan(200),
      reason: 'the top bar pills merged back into one strip',
    );

    await drawing.close();
  });
}
