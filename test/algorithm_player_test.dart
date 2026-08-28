import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logic_canvas/data/algorithms/algorithm_traces.dart';
import 'package:logic_canvas/domain/entities/viz_scene.dart';
import 'package:logic_canvas/presentation/widgets/viz/algorithm_player.dart';

Widget host(AlgorithmTrace trace, {ThemeMode mode = ThemeMode.light}) {
  return MaterialApp(
    themeMode: mode,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
    home: Scaffold(body: AlgorithmPlayer(trace: trace)),
  );
}

void main() {
  testWidgets('opens on step 1 with its caption and pattern visible', (
    tester,
  ) async {
    final trace = AlgorithmTraces.byId('two-sum')!;
    await tester.pumpWidget(host(trace));

    expect(find.text('Step 1/${trace.steps.length}'), findsOneWidget);
    expect(find.text(trace.steps.first.caption), findsOneWidget);
    expect(find.text(trace.pattern.toUpperCase()), findsOneWidget);
    expect(find.text(trace.patternIdea), findsOneWidget);
  });

  testWidgets('next and previous move through the steps', (tester) async {
    final trace = AlgorithmTraces.byId('two-sum')!;
    await tester.pumpWidget(host(trace));

    await tester.tap(find.byIcon(Icons.skip_next_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Step 2/${trace.steps.length}'), findsOneWidget);
    expect(find.text(trace.steps[1].caption), findsOneWidget);

    await tester.tap(find.byIcon(Icons.skip_previous_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Step 1/${trace.steps.length}'), findsOneWidget);
  });

  testWidgets('previous is disabled on the first step', (tester) async {
    await tester.pumpWidget(host(AlgorithmTraces.byId('two-sum')!));

    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.skip_previous_rounded),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('playing advances the animation on its own, and pause stops it', (
    tester,
  ) async {
    final trace = AlgorithmTraces.byId('two-sum')!;
    await tester.pumpWidget(host(trace));

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    // Two autoplay intervals should carry us forward two steps.
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pump(const Duration(milliseconds: 2700));
    expect(find.text('Step 3/${trace.steps.length}'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pumpAndSettle();

    // Once paused, time passing must not change the step.
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Step 3/${trace.steps.length}'), findsOneWidget);
  });

  testWidgets('autoplay stops at the end instead of looping past it', (
    tester,
  ) async {
    final trace = AlgorithmTraces.byId('valid-palindrome')!;
    await tester.pumpWidget(host(trace));

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    for (var i = 0; i < trace.steps.length + 3; i++) {
      await tester.pump(const Duration(milliseconds: 2700));
    }

    expect(
      find.text('Step ${trace.steps.length}/${trace.steps.length}'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('the takeaway appears only on the final step', (tester) async {
    final trace = AlgorithmTraces.byId('two-sum')!;
    await tester.pumpWidget(host(trace));

    expect(find.text('Remember this'), findsNothing);

    for (var i = 0; i < trace.steps.length - 1; i++) {
      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Remember this'), findsOneWidget);
    expect(find.text(trace.takeaway), findsOneWidget);

    // Next is disabled once there is nowhere further to go.
    final next = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.skip_next_rounded),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('restart returns to the first step', (tester) async {
    final trace = AlgorithmTraces.byId('two-sum')!;
    await tester.pumpWidget(host(trace));

    await tester.tap(find.byIcon(Icons.skip_next_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.skip_next_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Step 3/${trace.steps.length}'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.replay_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Step 1/${trace.steps.length}'), findsOneWidget);
  });

  testWidgets('speed cycles through the available rates', (tester) async {
    await tester.pumpWidget(host(AlgorithmTraces.byId('two-sum')!));

    expect(find.text('1x'), findsOneWidget);
    await tester.tap(find.text('1x'));
    await tester.pumpAndSettle();
    expect(find.text('1.5x'), findsOneWidget);

    await tester.tap(find.text('1.5x'));
    await tester.pumpAndSettle();
    expect(find.text('2x'), findsOneWidget);

    await tester.tap(find.text('2x'));
    await tester.pumpAndSettle();
    expect(find.text('0.5x'), findsOneWidget);
  });

  testWidgets('the copy-to-board action fires with the trace', (tester) async {
    final trace = AlgorithmTraces.byId('two-sum')!;
    AlgorithmTrace? copied;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlgorithmPlayer(trace: trace, onCopyToBoard: (t) => copied = t),
        ),
      ),
    );

    for (var i = 0; i < trace.steps.length - 1; i++) {
      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Put this on my board'));
    await tester.tap(find.text('Put this on my board'));
    await tester.pump();

    expect(copied?.id, trace.id);
  });

  group('every trace renders end to end without overflowing', () {
    for (final trace in AlgorithmTraces.all) {
      testWidgets('${trace.title} (light and dark)', (tester) async {
        // A phone-sized surface, where overflow is most likely.
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          await tester.pumpWidget(host(trace, mode: mode));

          for (var i = 0; i < trace.steps.length; i++) {
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${trace.title} threw on step ${i + 1} in $mode',
            );
            if (i < trace.steps.length - 1) {
              await tester.tap(find.byIcon(Icons.skip_next_rounded));
              await tester.pump();
            }
          }
        }
      });
    }
  });
}
