import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logic_canvas/data/repositories/board_store.dart';
import 'package:logic_canvas/data/services/handwriting_service.dart';
import 'package:logic_canvas/data/services/icloud_sync_service.dart';
import 'package:logic_canvas/data/services/ml_shape_service.dart';
import 'package:logic_canvas/data/services/snapshot_service.dart';
import 'package:logic_canvas/domain/entities/board_snapshot.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_state.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';

Stroke textStroke(String text) => Stroke(
  points: const [Offset(10, 10)],
  color: Colors.white,
  strokeWidth: 2,
  type: StrokeType.text,
  text: text,
);

/// The user's report was "I lost all my progress". These tests pin down the
/// guarantee that prevents it: nothing destroys work without first saving a
/// copy that can be restored.
void main() {
  late Directory tempDir;
  late BoardStore store;
  late SnapshotService snapshots;
  late SettingsCubit settings;

  DrawingCubit buildCubit() {
    return DrawingCubit(
      HandwritingRecognitionService(),
      MLShapeService(),
      ICloudSyncService(settings),
      store,
      snapshots,
    );
  }

  Future<DrawingCubit> loadedCubit() async {
    final cubit = buildCubit();
    await cubit.stream.firstWhere((s) => s.isLoaded);
    return cubit;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('drawing_cubit_test');
    Hive.init(tempDir.path);
    store = BoardStore();
    snapshots = SnapshotService();
    settings = SettingsCubit(HandwritingRecognitionService(), MLShapeService());
  });

  tearDown(() async {
    await settings.close();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('clearing a board is recoverable', () async {
    final cubit = await loadedCubit();
    cubit.addStroke(textStroke('my whole approach'));
    await cubit.flushPendingSave();

    await cubit.clear();
    expect(cubit.state.activeStrokes, isEmpty);

    final saved = await cubit.listSnapshots();
    expect(saved, isNotEmpty);
    expect(saved.first.reason, SnapshotReason.beforeClear);

    final outcome = await cubit.restoreSnapshot(saved.first.id);
    expect(outcome.applied, isTrue);
    expect(cubit.state.activeStrokes.single.text, 'my whole approach');

    await cubit.close();
  });

  test(
    'clearing an already-empty board does not burn a snapshot slot',
    () async {
      final cubit = await loadedCubit();
      await cubit.clear();

      expect(await cubit.listSnapshots(), isEmpty);
      await cubit.close();
    },
  );

  test('deleting a board with work in it is recoverable', () async {
    final cubit = await loadedCubit();
    cubit.createNewBoard('Sliding Window');
    cubit.addStroke(textStroke('window notes'));
    await cubit.flushPendingSave();

    await cubit.deleteBoard('Sliding Window');
    expect(cubit.state.boardIds, isNot(contains('Sliding Window')));

    final saved = await cubit.listSnapshots();
    expect(saved.first.reason, SnapshotReason.beforeBoardDelete);

    await cubit.restoreSnapshot(saved.first.id);
    expect(cubit.state.boardIds, contains('Sliding Window'));
    expect(cubit.state.boards['Sliding Window']!.single.text, 'window notes');

    await cubit.close();
  });

  test('replacing boards from a backup saves the old ones first', () async {
    final cubit = await loadedCubit();
    cubit.addStroke(textStroke('work I did today'));
    await cubit.flushPendingSave();

    // Stand-in for a smaller/older copy arriving from iCloud.
    final incoming = {
      'boards': {
        'From Cloud': [textStroke('older cloud copy').toJson()],
      },
      'boardIds': ['From Cloud'],
      'activeBoardId': 'From Cloud',
      'boardProblems': <String, String?>{},
    };

    final outcome = await cubit.applyRestoredState(
      incoming,
      reason: SnapshotReason.beforeCloudRestore,
    );

    expect(outcome.applied, isTrue);
    expect(cubit.state.boardIds, ['From Cloud']);

    // Today's work must still be reachable.
    final saved = await cubit.listSnapshots();
    final beforeRestore = saved.firstWhere(
      (s) => s.reason == SnapshotReason.beforeCloudRestore,
    );
    await cubit.restoreSnapshot(beforeRestore.id);
    expect(
      cubit.state.boards.values.expand((s) => s).map((s) => s.text),
      contains('work I did today'),
    );

    await cubit.close();
  });

  group('undo and redo', () {
    test('undo removes the last stroke and redo puts it back', () async {
      final cubit = await loadedCubit();
      cubit.addStroke(textStroke('first'));
      cubit.addStroke(textStroke('second'));

      cubit.undo();
      expect(cubit.state.activeStrokes.length, 1);
      expect(cubit.state.redoStack.length, 1);

      cubit.redo();
      expect(cubit.state.activeStrokes.length, 2);
      expect(cubit.state.activeStrokes.last.text, 'second');
      expect(cubit.state.redoStack, isEmpty);

      await cubit.close();
    });

    test('each change is actually emitted, so the board repaints', () async {
      final cubit = await loadedCubit();
      final emitted = <DrawingState>[];
      final sub = cubit.stream.listen(emitted.add);

      cubit.addStroke(textStroke('a'));
      cubit.undo();
      cubit.redo();
      await Future<void>.delayed(Duration.zero);

      expect(
        emitted.length,
        3,
        reason: 'a silent state change would leave the canvas stale',
      );

      await sub.cancel();
      await cubit.close();
    });

    test('touching the canvas does not destroy the redo stack', () async {
      // startStroke fires on pointer-down. It used to clear redo there, so a
      // pan, a stray finger, or a tap that never became a stroke silently
      // threw away everything you had undone.
      final cubit = await loadedCubit();
      cubit.addStroke(textStroke('work'));
      cubit.undo();
      expect(cubit.state.redoStack.length, 1);

      cubit.startStroke();
      await cubit.endStroke(null, false); // pointer went down, then nothing

      expect(
        cubit.state.redoStack.length,
        1,
        reason: 'redo must survive a touch that produced no stroke',
      );

      cubit.redo();
      expect(cubit.state.activeStrokes.single.text, 'work');

      await cubit.close();
    });

    test('drawing a real stroke does invalidate redo', () async {
      final cubit = await loadedCubit();
      cubit.addStroke(textStroke('one'));
      cubit.undo();
      expect(cubit.state.redoStack.length, 1);

      cubit.startStroke();
      await cubit.endStroke(textStroke('new work'), false);

      expect(
        cubit.state.redoStack,
        isEmpty,
        reason: 'a committed stroke makes the undone branch unreachable',
      );

      await cubit.close();
    });

    test('undo on an empty board is a no-op', () async {
      final cubit = await loadedCubit();
      cubit.undo();
      expect(cubit.state.activeStrokes, isEmpty);
      expect(cubit.state.redoStack, isEmpty);
      await cubit.close();
    });

    test('undo and redo only affect the active board', () async {
      final cubit = await loadedCubit();
      cubit.createNewBoard('Other');
      cubit.addStroke(textStroke('other board'));
      cubit.createNewBoard('Mine');
      cubit.addStroke(textStroke('mine'));

      cubit.undo();
      expect(cubit.state.activeStrokes, isEmpty);
      expect(cubit.state.boards['Other']!.single.text, 'other board');

      await cubit.close();
    });
  });

  group('writing then undoing', () {
    Stroke penStroke() => Stroke(
      points: List.generate(12, (i) => Offset(i * 3.0, i * 2.0)),
      color: Colors.white,
      strokeWidth: 2,
    );

    test('undo after writing is not reversed by late recognition', () async {
      // Handwriting recognition runs 800ms after the pen lifts and rewrites
      // strokes by index. It used to still fire after an undo, rewriting the
      // board a moment later — which is what made undo look broken when
      // writing, and only when writing.
      final cubit = await loadedCubit();

      cubit.startStroke();
      await cubit.endStroke(penStroke(), false, enableHandwriting: true);
      expect(cubit.state.activeStrokes.length, 1);

      cubit.undo();
      expect(cubit.state.activeStrokes, isEmpty);

      // Wait past the recognition delay; the board must stay as the user left it.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(
        cubit.state.activeStrokes,
        isEmpty,
        reason: 'recognition must not resurrect strokes after an undo',
      );
      expect(cubit.state.redoStack.length, 1);

      await cubit.close();
    });

    test('redo after writing survives the recognition window', () async {
      final cubit = await loadedCubit();

      cubit.startStroke();
      await cubit.endStroke(penStroke(), false, enableHandwriting: true);
      cubit.undo();
      cubit.redo();
      expect(cubit.state.activeStrokes.length, 1);

      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(
        cubit.state.activeStrokes.length,
        1,
        reason: 'a redone stroke must not be rewritten by stale recognition',
      );

      await cubit.close();
    });

    test('switching boards cancels recognition for the old board', () async {
      final cubit = await loadedCubit();
      final first = cubit.state.activeBoardId;

      cubit.startStroke();
      await cubit.endStroke(penStroke(), false, enableHandwriting: true);

      cubit.createNewBoard('Second');
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(
        cubit.state.boards['Second'],
        isEmpty,
        reason: 'the other board must not receive the recognised text',
      );
      expect(cubit.state.boards[first]!.length, 1);

      await cubit.close();
    });

    test('clearing cancels pending recognition', () async {
      final cubit = await loadedCubit();
      cubit.startStroke();
      await cubit.endStroke(penStroke(), false, enableHandwriting: true);

      await cubit.clear();
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(cubit.state.activeStrokes, isEmpty);
      await cubit.close();
    });
  });

  group('downloading merges instead of replacing', () {
    /// Builds a cloud-shaped payload from board name -> note text.
    Map<String, dynamic> cloud(Map<String, String> boards) => {
      'boards': boards.map(
        (name, text) => MapEntry(name, [textStroke(text).toJson()]),
      ),
      'boardIds': boards.keys.toList(),
      'activeBoardId': boards.keys.first,
      'boardProblems': <String, String?>{},
    };

    test('a board that already has work is never overwritten', () async {
      final cubit = await loadedCubit();
      cubit.createNewBoard('Two Sum');
      cubit.addStroke(textStroke('my own working'));
      await cubit.flushPendingSave();

      final outcome = await cubit.mergeRestoredState(
        cloud({'Two Sum': 'the cloud version'}),
        reason: SnapshotReason.beforeCloudRestore,
      );

      expect(outcome.applied, isFalse);
      expect(outcome.skipped, 1);
      expect(
        cubit.state.boards['Two Sum']!.single.text,
        'my own working',
        reason: 'local work must survive a download',
      );

      await cubit.close();
    });

    test('a board only in the cloud is copied down', () async {
      final cubit = await loadedCubit();
      cubit.createNewBoard('Mine');
      cubit.addStroke(textStroke('local note'));
      await cubit.flushPendingSave();

      final outcome = await cubit.mergeRestoredState(
        cloud({'From iPad': 'cloud note'}),
        reason: SnapshotReason.beforeCloudRestore,
      );

      expect(outcome.applied, isTrue);
      expect(outcome.added, 1);
      expect(cubit.state.boards['From iPad']!.single.text, 'cloud note');
      expect(cubit.state.boards['Mine']!.single.text, 'local note');

      await cubit.close();
    });

    test('an empty local board is filled from the cloud', () async {
      final cubit = await loadedCubit();
      cubit.createNewBoard('Blank');
      await cubit.flushPendingSave();

      final outcome = await cubit.mergeRestoredState(
        cloud({'Blank': 'recovered work'}),
        reason: SnapshotReason.beforeCloudRestore,
      );

      expect(outcome.applied, isTrue);
      expect(outcome.filled, 1);
      expect(cubit.state.boards['Blank']!.single.text, 'recovered work');

      await cubit.close();
    });

    test('mixed download adds, fills and keeps in one pass', () async {
      final cubit = await loadedCubit();
      cubit.createNewBoard('HasWork');
      cubit.addStroke(textStroke('do not touch'));
      cubit.createNewBoard('Empty');
      await cubit.flushPendingSave();

      final outcome = await cubit.mergeRestoredState(
        cloud({
          'HasWork': 'cloud copy',
          'Empty': 'filled from cloud',
          'BrandNew': 'arrived',
        }),
        reason: SnapshotReason.beforeCloudRestore,
      );

      expect(outcome.added, 1);
      expect(outcome.filled, 1);
      expect(outcome.skipped, 1);
      expect(cubit.state.boards['HasWork']!.single.text, 'do not touch');
      expect(cubit.state.boards['Empty']!.single.text, 'filled from cloud');
      expect(cubit.state.boards['BrandNew']!.single.text, 'arrived');

      await cubit.close();
    });

    test(
      'nothing new means nothing changes, and no snapshot is burned',
      () async {
        final cubit = await loadedCubit();
        cubit.createNewBoard('Same');
        cubit.addStroke(textStroke('mine'));
        await cubit.flushPendingSave();
        final before = (await cubit.listSnapshots()).length;

        final outcome = await cubit.mergeRestoredState(
          cloud({'Same': 'cloud'}),
          reason: SnapshotReason.beforeCloudRestore,
        );

        expect(outcome.applied, isFalse);
        expect(outcome.message, contains('already on this device'));
        expect((await cubit.listSnapshots()).length, before);

        await cubit.close();
      },
    );

    test('a merge that does change things is still undoable', () async {
      final cubit = await loadedCubit();
      cubit.createNewBoard('Local');
      cubit.addStroke(textStroke('before the merge'));
      await cubit.flushPendingSave();

      await cubit.mergeRestoredState(
        cloud({'Incoming': 'new board'}),
        reason: SnapshotReason.beforeCloudRestore,
      );
      expect(cubit.state.boardIds, contains('Incoming'));

      final saved = (await cubit.listSnapshots()).first;
      await cubit.restoreSnapshot(saved.id);
      expect(cubit.state.boardIds, isNot(contains('Incoming')));
      expect(cubit.state.boards['Local']!.single.text, 'before the merge');

      await cubit.close();
    });

    test('an unreadable payload leaves everything alone', () async {
      final cubit = await loadedCubit();
      cubit.addStroke(textStroke('safe'));
      await cubit.flushPendingSave();

      final outcome = await cubit.mergeRestoredState({
        'boards': {'X': 'not a list'},
      }, reason: SnapshotReason.beforeCloudRestore);

      expect(outcome.applied, isFalse);
      expect(cubit.state.activeStrokes.single.text, 'safe');

      await cubit.close();
    });
  });

  test('an empty or unreadable backup changes nothing', () async {
    final cubit = await loadedCubit();
    cubit.addStroke(textStroke('keep me'));
    await cubit.flushPendingSave();

    final empty = await cubit.applyRestoredState({
      'boards': <String, dynamic>{},
    }, reason: SnapshotReason.beforeImport);
    expect(empty.applied, isFalse);
    expect(cubit.state.activeStrokes.single.text, 'keep me');

    final garbage = await cubit.applyRestoredState({
      'boards': {'X': 'not a list'},
    }, reason: SnapshotReason.beforeImport);
    expect(garbage.applied, isFalse);
    expect(cubit.state.activeStrokes.single.text, 'keep me');

    await cubit.close();
  });

  test('boards survive a restart, stored per board', () async {
    final first = await loadedCubit();
    first.createNewBoard('Trees');
    first.addStroke(textStroke('bfs uses a queue'));
    first.switchToBoard(first.state.boardIds.first);
    first.addStroke(textStroke('first board note'));
    await first.flushPendingSave();
    await first.close();

    final second = await loadedCubit();
    expect(second.state.boardIds, contains('Trees'));
    expect(second.state.boards['Trees']!.single.text, 'bfs uses a queue');

    // Each board is its own key, so a single failure cannot take both.
    final box = await Hive.openBox(BoardStore.boxName);
    expect(box.get(BoardStore.boardKey('Trees')), isNotNull);

    await second.close();
  });

  test('a damaged board is reported rather than silently emptied', () async {
    final first = await loadedCubit();
    first.createNewBoard('Graphs');
    first.addStroke(textStroke('dfs notes'));
    await first.flushPendingSave();
    await first.close();

    final box = await Hive.openBox(BoardStore.boxName);
    await box.put(BoardStore.boardKey('Graphs'), '{corrupt');

    final second = await loadedCubit();
    expect(second.state.damagedBoardIds, contains('Graphs'));
    // The other board is untouched.
    expect(second.state.boardIds.length, greaterThan(1));

    second.acknowledgeDamagedBoards();
    expect(second.state.damagedBoardIds, isEmpty);

    await second.close();
  });

  test('renaming moves the stored board rather than orphaning it', () async {
    final first = await loadedCubit();
    first.createNewBoard('Old Name');
    first.addStroke(textStroke('survives the rename'));
    await first.flushPendingSave();
    await first.renameBoard('Old Name', 'New Name');
    await first.flushPendingSave();
    await first.close();

    final second = await loadedCubit();
    expect(second.state.boardIds, contains('New Name'));
    expect(second.state.boardIds, isNot(contains('Old Name')));
    expect(second.state.boards['New Name']!.single.text, 'survives the rename');

    await second.close();
  });

  test('a fresh install takes no snapshot of nothing', () async {
    final cubit = await loadedCubit();
    expect(await cubit.listSnapshots(), isEmpty);
    await cubit.close();
  });

  test('exportState round-trips through applyRestoredState', () async {
    final cubit = await loadedCubit();
    cubit.createNewBoard('Exported');
    cubit.addStroke(textStroke('exported note'));
    await cubit.flushPendingSave();

    final exported = cubit.exportState();

    await cubit.clear();
    expect(cubit.state.activeStrokes, isEmpty);

    final outcome = await cubit.applyRestoredState(
      exported,
      reason: SnapshotReason.beforeImport,
    );
    expect(outcome.applied, isTrue);
    expect(cubit.state.boards['Exported']!.single.text, 'exported note');

    await cubit.close();
  });
}
