import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logic_canvas/data/repositories/board_store.dart';
import 'package:logic_canvas/data/services/backup_service.dart';
import 'package:logic_canvas/data/services/snapshot_service.dart';
import 'package:logic_canvas/domain/entities/board_snapshot.dart';
import 'package:logic_canvas/domain/entities/stroke.dart';

Stroke penStroke({double x = 0, double y = 0}) => Stroke(
  points: [Offset(x, y), Offset(x + 10, y + 10)],
  color: Colors.white,
  strokeWidth: 2,
);

Stroke textStroke(String text, {double x = 0, double y = 0}) => Stroke(
  points: [Offset(x, y)],
  color: Colors.white,
  strokeWidth: 2,
  type: StrokeType.text,
  text: text,
);

Map<String, dynamic> stateWith(Map<String, List<Stroke>> boards) {
  return {
    'boards': boards.map(
      (key, value) => MapEntry(key, value.map((s) => s.toJson()).toList()),
    ),
    'boardIds': boards.keys.toList(),
    'activeBoardId': boards.keys.first,
    'boardProblems': <String, String?>{},
  };
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('logic_canvas_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('SnapshotService', () {
    test('summarize counts boards and strokes', () {
      final state = stateWith({
        'A': [penStroke(), penStroke()],
        'B': [penStroke()],
      });

      final counts = SnapshotService.summarize(state);
      expect(counts.boardCount, 2);
      expect(counts.strokeCount, 3);
    });

    test('summarize tolerates malformed payloads instead of throwing', () {
      expect(SnapshotService.summarize({}).boardCount, 0);
      expect(SnapshotService.summarize({'boards': 'not a map'}).strokeCount, 0);
    });

    test('capture then restore round-trips the exact state', () async {
      final service = SnapshotService();
      final state = stateWith({
        'Two Sum': [textStroke('use a hashmap'), penStroke()],
      });

      final meta = await service.capture(
        state,
        reason: SnapshotReason.beforeCloudRestore,
      );

      expect(meta, isNotNull);
      expect(meta!.boardCount, 1);
      expect(meta.strokeCount, 2);
      expect(meta.reason, SnapshotReason.beforeCloudRestore);

      final restored = await service.restore(meta.id);
      expect(restored, isNotNull);
      expect(jsonEncode(restored), jsonEncode(state));
    });

    test('skips a snapshot identical to the most recent one', () async {
      final service = SnapshotService();
      final state = stateWith({
        'A': [penStroke()],
      });

      final first = await service.capture(
        state,
        reason: SnapshotReason.periodic,
        now: DateTime(2026, 1, 1),
      );
      final second = await service.capture(
        state,
        reason: SnapshotReason.periodic,
        now: DateTime(2026, 1, 2),
      );

      expect(first, isNotNull);
      expect(second, isNull, reason: 'identical content should be skipped');
      expect((await service.list()).length, 1);
    });

    test(
      'keeps only the newest maxSnapshots and deletes old payloads',
      () async {
        final service = SnapshotService();

        for (var i = 0; i < SnapshotService.maxSnapshots + 5; i++) {
          await service.capture(
            stateWith({'A': List.generate(i + 1, (_) => penStroke())}),
            reason: SnapshotReason.periodic,
            now: DateTime(2026, 1, 1).add(Duration(minutes: i)),
          );
        }

        final metas = await service.list();
        expect(metas.length, SnapshotService.maxSnapshots);

        // Newest first, and the oldest payloads are gone from the box.
        expect(metas.first.createdAt.isAfter(metas.last.createdAt), isTrue);

        final box = await Hive.openBox(SnapshotService.boxName);
        final payloadKeys = box.keys.where(
          (k) => k is String && k.startsWith('snap::'),
        );
        expect(payloadKeys.length, SnapshotService.maxSnapshots);
      },
    );

    test('restore returns null for an unknown id', () async {
      final service = SnapshotService();
      expect(await service.restore('does-not-exist'), isNull);
    });

    test('delete removes both the meta and the payload', () async {
      final service = SnapshotService();
      final meta = await service.capture(
        stateWith({
          'A': [penStroke()],
        }),
        reason: SnapshotReason.manual,
      );

      await service.delete(meta!.id);
      expect(await service.list(), isEmpty);
      expect(await service.restore(meta.id), isNull);
    });

    test(
      'an empty snapshot is flagged so the UI can warn before restoring',
      () {
        final meta = SnapshotMeta(
          id: '1',
          createdAt: DateTime(2026, 1, 1),
          reason: SnapshotReason.periodic,
          boardCount: 1,
          strokeCount: 0,
          contentHash: 0,
        );
        expect(meta.isEmpty, isTrue);
        expect(meta.summary, '1 board · 0 strokes');
      },
    );
  });

  group('BoardStore', () {
    test('load returns null on a brand new install', () async {
      final store = BoardStore();
      expect(await store.load(), isNull);
    });

    test('saves and reloads boards independently', () async {
      final store = BoardStore();
      await store.saveAll(
        LoadedBoards(
          boards: {
            'A': [textStroke('note a')],
            'B': [penStroke(), penStroke()],
          },
          boardIds: const ['A', 'B'],
          activeBoardId: 'B',
          boardProblems: const {'A': '01'},
        ),
      );

      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.boardIds, ['A', 'B']);
      expect(loaded.activeBoardId, 'B');
      expect(loaded.boards['A']!.single.text, 'note a');
      expect(loaded.boards['B']!.length, 2);
      expect(loaded.boardProblems['A'], '01');
    });

    test('one corrupt board does not take the others down', () async {
      final store = BoardStore();
      await store.saveAll(
        LoadedBoards(
          boards: {
            'Good': [textStroke('survives')],
            'Bad': [penStroke()],
          },
          boardIds: const ['Good', 'Bad'],
          activeBoardId: 'Good',
          boardProblems: const {},
        ),
      );

      // Corrupt exactly one board's payload.
      final box = await Hive.openBox(BoardStore.boxName);
      await box.put(BoardStore.boardKey('Bad'), '{not valid json');

      final loaded = await store.load();
      expect(loaded!.failedBoardIds, ['Bad']);
      expect(loaded.boards['Good']!.single.text, 'survives');
      expect(loaded.boards['Bad'], isEmpty);
    });

    test('migrates the legacy single-blob state and keeps the blob', () async {
      final box = await Hive.openBox(BoardStore.boxName);
      await box.put(BoardStore.legacyStateKey, {
        'boards': {
          'Old Board': [textStroke('legacy note').toJson()],
        },
        'boardIds': ['Old Board'],
        'activeBoardId': 'Old Board',
        'boardProblems': {'Old Board': '07'},
      });

      final store = BoardStore();
      final loaded = await store.load();

      expect(loaded!.migratedFromLegacy, isTrue);
      expect(loaded.boards['Old Board']!.single.text, 'legacy note');
      expect(loaded.boardProblems['Old Board'], '07');

      // The old blob must survive as a last-resort backup.
      expect(box.get(BoardStore.legacyStateKey), isNotNull);

      // And a second load now uses the new per-board layout.
      final again = await store.load();
      expect(again!.migratedFromLegacy, isFalse);
      expect(again.boards['Old Board']!.single.text, 'legacy note');
    });

    test('falls back to the legacy blob when the index is corrupt', () async {
      final box = await Hive.openBox(BoardStore.boxName);
      await box.put(BoardStore.legacyStateKey, {
        'boards': {
          'Rescued': [textStroke('from the blob').toJson()],
        },
        'boardIds': ['Rescued'],
        'activeBoardId': 'Rescued',
        'boardProblems': {},
      });
      await box.put(BoardStore.indexKey, 'not json at all');

      final loaded = await BoardStore().load();
      expect(loaded!.boards['Rescued']!.single.text, 'from the blob');
    });

    test('renameBoard moves the payload to the new key', () async {
      final store = BoardStore();
      await store.saveBoard('Before', [textStroke('kept')]);
      await store.renameBoard('Before', 'After');

      final box = await Hive.openBox(BoardStore.boxName);
      expect(box.get(BoardStore.boardKey('Before')), isNull);
      expect(box.get(BoardStore.boardKey('After')), isNotNull);
    });

    test('an empty index still yields a usable board', () async {
      final store = BoardStore();
      await store.saveIndex(
        boardIds: const [],
        activeBoardId: 'gone',
        boardProblems: const {},
      );

      final loaded = await store.load();
      expect(loaded!.boardIds, [BoardStore.fallbackBoardId]);
      expect(loaded.activeBoardId, BoardStore.fallbackBoardId);
    });
  });

  group('BackupService', () {
    test('encode then parse round-trips the state', () {
      final state = stateWith({
        'A': [textStroke('hello'), penStroke()],
      });

      final encoded = BackupService.encodeBackup(state);
      final result = BackupService.parseBackup(encoded);

      expect(result, isA<BackupParsed>());
      final parsed = result as BackupParsed;
      expect(parsed.boardCount, 1);
      expect(parsed.strokeCount, 2);
      expect(jsonEncode(parsed.state), jsonEncode(state));
      expect(parsed.summary, '1 board · 2 strokes');
    });

    test('accepts a bare state map, as stored in iCloud', () {
      final state = stateWith({
        'A': [penStroke()],
      });

      final result = BackupService.parseBackup(jsonEncode(state));
      expect(result, isA<BackupParsed>());
      expect((result as BackupParsed).boardCount, 1);
    });

    test('rejects junk with a message a person can act on', () {
      expect(BackupService.parseBackup(''), isA<BackupInvalid>());
      expect(BackupService.parseBackup('hello there'), isA<BackupInvalid>());
      expect(BackupService.parseBackup('[1,2,3]'), isA<BackupInvalid>());
      expect(BackupService.parseBackup('{"nope": true}'), isA<BackupInvalid>());

      final invalid = BackupService.parseBackup('hello there') as BackupInvalid;
      expect(invalid.message, contains('not valid JSON'));
    });

    test('refuses a backup from a newer app version', () {
      final future = jsonEncode({
        'format': BackupService.formatTag,
        'version': BackupService.formatVersion + 1,
        'state': stateWith({
          'A': [penStroke()],
        }),
      });

      final result = BackupService.parseBackup(future);
      expect(result, isA<BackupInvalid>());
      expect((result as BackupInvalid).message, contains('newer version'));
    });

    test('flags a damaged board payload', () {
      final result = BackupService.parseBackup(
        jsonEncode({
          'boards': {'A': 'not a list'},
        }),
      );
      expect(result, isA<BackupInvalid>());
      expect((result as BackupInvalid).message, contains('damaged'));
    });
  });
}
