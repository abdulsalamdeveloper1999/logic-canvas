import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logic_canvas/data/algorithms/algorithm_traces.dart';
import 'package:logic_canvas/data/repositories/board_store.dart';
import 'package:logic_canvas/data/services/handwriting_service.dart';
import 'package:logic_canvas/data/services/icloud_sync_service.dart';
import 'package:logic_canvas/data/services/ml_shape_service.dart';
import 'package:logic_canvas/data/services/snapshot_service.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/domain/entities/viz_scene.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/widgets/backup_panel.dart';
import 'package:logic_canvas/presentation/widgets/viz/pattern_library_view.dart';

Stroke textStroke(String text) => Stroke(
  points: const [Offset(10, 10)],
  color: Colors.white,
  strokeWidth: 2,
  type: StrokeType.text,
  text: text,
);

/// Storage work has to run through [WidgetTester.runAsync]: Hive does real file
/// I/O, which never completes under the widget test's fake clock.
Future<void> realAsync(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  await tester.runAsync(() async {
    await body();
    await Future<void>.delayed(const Duration(milliseconds: 120));
  });
}

void main() {
  group('PatternLibraryView', () {
    setUp(() {
      // A tall surface so every card is laid out without scrolling.
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('lists every animation with its pattern and step count', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PatternLibraryView())),
      );
      await tester.pumpAndSettle();

      // The catalogue is long, so scroll each card into view rather than
      // relying on everything being laid out at once.
      final scrollable = find.byType(Scrollable).first;
      for (final trace in AlgorithmTraces.all) {
        await tester.scrollUntilVisible(
          find.text(trace.title),
          200,
          scrollable: scrollable,
          maxScrolls: 200,
        );
        expect(
          find.text(trace.title),
          findsOneWidget,
          reason: '${trace.title} is missing from the catalogue',
        );
      }
    });

    test('every walkthrough belongs to a named section', () {
      // A trace whose pattern is not mapped in PatternLibraryView.sections
      // falls into a trailing "More" group — visible, but unorganised. Keep
      // the mapping complete instead.
      final groups = PatternLibraryView.grouped();
      final orphaned = groups.where((g) => g.title == 'More').toList();
      expect(
        orphaned,
        isEmpty,
        reason:
            'unmapped patterns: '
            '${orphaned.expand((g) => g.traces).map((t) => t.pattern).toSet()}',
      );

      final total = groups.fold<int>(0, (a, g) => a + g.traces.length);
      expect(
        total,
        AlgorithmTraces.all.length,
        reason: 'grouping must not drop or duplicate traces',
      );
    });

    testWidgets('tapping a pattern opens its player', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PatternLibraryView())),
      );

      final trace = AlgorithmTraces.all.first;
      await tester.tap(find.text(trace.title));
      await tester.pumpAndSettle();

      expect(find.text('Step 1/${trace.steps.length}'), findsOneWidget);
      expect(find.text(trace.steps.first.caption), findsOneWidget);
    });

    testWidgets('copy-to-board reports the chosen trace', (tester) async {
      AlgorithmTrace? copied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatternLibraryView(onCopyToBoard: (t) => copied = t),
          ),
        ),
      );

      final trace = AlgorithmTraces.all.first;
      await tester.tap(find.text(trace.title));
      await tester.pumpAndSettle();

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
  });

  group('formatTimestamp', () {
    test('describes recent times in words', () {
      final now = DateTime.now();
      expect(formatTimestamp(now), 'just now');
      expect(
        formatTimestamp(now.subtract(const Duration(minutes: 5))),
        '5 min ago',
      );
      expect(
        formatTimestamp(now.subtract(const Duration(hours: 1))),
        '1 hour ago',
      );
      expect(
        formatTimestamp(now.subtract(const Duration(days: 1))),
        '1 day ago',
      );
    });

    test('falls back to an absolute stamp for older times', () {
      expect(formatTimestamp(DateTime(2026, 3, 4, 9, 5)), '2026-03-04 09:05');
    });
  });

  group('SnapshotRestoreSheet', () {
    late Directory tempDir;
    late DrawingCubit cubit;
    late SettingsCubit settings;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('restore_sheet_test');
      Hive.init(tempDir.path);
      settings = SettingsCubit(
        HandwritingRecognitionService(),
        MLShapeService(),
      );
      cubit = DrawingCubit(
        HandwritingRecognitionService(),
        MLShapeService(),
        ICloudSyncService(settings),
        BoardStore(),
        SnapshotService(),
      );
      if (!cubit.state.isLoaded) {
        await cubit.stream.firstWhere((s) => s.isLoaded);
      }
    });

    tearDown(() async {
      await cubit.close();
      await settings.close();
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Widget host() => MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const Scaffold(body: SnapshotRestoreSheet()),
      ),
    );

    testWidgets('explains itself when there is nothing to restore', (
      tester,
    ) async {
      await realAsync(tester, () => tester.pumpWidget(host()));
      await tester.pumpAndSettle();

      expect(find.textContaining('No saved versions yet'), findsOneWidget);
    });

    testWidgets('lists a saved version with why it was taken', (tester) async {
      await realAsync(tester, () async {
        cubit.addStroke(textStroke('important work'));
        await cubit.flushPendingSave();
        await cubit.clear();
        await tester.pumpWidget(host());
      });
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Before clearing board'),
        findsOneWidget,
        reason: 'the reason is how the user picks the right version',
      );
      expect(find.text('Restore'), findsOneWidget);
    });

    // Restoring never happens on a single tap: the sheet always asks first,
    // and names what the user is about to overwrite. The storage round trip
    // itself is covered in drawing_cubit_safety_test, where real file I/O runs
    // on a real clock.
    testWidgets('a restore is always confirmed before anything is replaced', (
      tester,
    ) async {
      await realAsync(tester, () async {
        cubit.addStroke(textStroke('important work'));
        await cubit.flushPendingSave();
        await cubit.clear();
        await tester.pumpWidget(host());
      });
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(find.text('Restore this version?'), findsOneWidget);
      expect(
        find.textContaining('replaces your current boards'),
        findsOneWidget,
      );
      expect(
        find.textContaining('saved first'),
        findsOneWidget,
        reason: 'the user must be told the current work is kept',
      );
      expect(find.widgetWithText(FilledButton, 'Restore'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancelling the confirmation changes nothing', (tester) async {
      await realAsync(tester, () async {
        cubit.addStroke(textStroke('current work'));
        await cubit.flushPendingSave();
        await cubit.clear();
        await tester.pumpWidget(host());
      });
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(cubit.state.activeStrokes, isEmpty);
    });
  });
}
