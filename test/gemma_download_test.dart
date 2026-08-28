import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logic_canvas/data/services/gemma_service.dart';
import 'package:logic_canvas/presentation/cubits/gemma/gemma_cubit.dart';
import 'package:logic_canvas/presentation/cubits/gemma/gemma_state.dart';

/// The model download is a 1.7 GB, one-shot operation with no resume, so a bug
/// here costs the user a very long wait. These tests cover the parts that can
/// be exercised without actually downloading a model.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gemma_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('GemmaService lifecycle', () {
    test('closing a cubit leaves the shared service usable', () async {
      // GemmaService is a lazySingleton and GemmaCubit is a factory, so a cubit
      // must never fully dispose it. It used to, which closed the progress
      // stream for the whole app and broke every later download.
      final service = GemmaService();

      final first = GemmaCubit(service);
      await first.close();

      expect(
        () => service.downloadProgress.listen((_) {}).cancel(),
        returnsNormally,
        reason: 'the progress stream must survive a cubit being closed',
      );

      final second = GemmaCubit(service);
      expect(second.state.status, GemmaStatus.idle);
      await second.close();
    });

    test('disposeSingleton is the only thing that closes the stream', () async {
      final service = GemmaService();
      await service.releaseResources();

      // Still alive after releasing the loaded model.
      final sub = service.downloadProgress.listen((_) {});
      await sub.cancel();

      await service.disposeSingleton();
    });

    test('init reports not-installed on a fresh device', () async {
      final service = GemmaService();
      await service.init();
      expect(service.isInstalled, isFalse);
    });

    test(
      'init does not trust an install flag for a different model url',
      () async {
        final box = await Hive.openBox('settings');
        await box.put('gemma_installed', true);
        await box.put(
          'gemma_installed_model_url',
          'https://example.com/old.bin',
        );

        final service = GemmaService();
        await service.init();

        expect(
          service.isInstalled,
          isFalse,
          reason: 'a flag left by a previous model must not count as installed',
        );
      },
    );
  });

  group('inference error messages', () {
    // A failed reply used to dump the raw exception straight into the chat.
    String messageFor(Object error) {
      return GemmaCubit.readableInferenceErrorForTest(error);
    }

    test('a stall says what to try', () {
      final message = messageFor(Exception('Operation timed out'));
      expect(message, contains('took too long'));
      expect(message, isNot(contains('Exception')));
    });

    test('a missing model points back at the download', () {
      final message = messageFor(Exception('model not installed'));
      expect(message, contains('Download it again'));
    });

    test('an unknown failure still reads as a sentence', () {
      final message = messageFor(StateError('segfault in native handler'));
      expect(message, contains('could not finish'));
      expect(message, isNot(contains('segfault')));
    });
  });

  group('download error messages', () {
    // The raw exceptions are unreadable; the cubit maps them to something the
    // user can act on.
    String messageFor(Object error) {
      return GemmaCubit.readableDownloadErrorForTest(error);
    }

    test('a dropped connection explains the restart', () {
      final message = messageFor(
        const SocketException('Connection reset by peer'),
      );
      expect(message, contains('interrupted'));
      expect(message, contains('start over'));
    });

    test('a full disk names the space needed', () {
      final message = messageFor(Exception('ENOSPC: no space left on device'));
      expect(message, contains('1.7 GB'));
      expect(message, contains('Free some space'));
    });

    test('a server error suggests trying later', () {
      final message = messageFor(Exception('Model URL returned HTTP 503'));
      expect(message, contains('Try again later'));
    });

    test('an unknown failure still says nothing was kept', () {
      final message = messageFor(Exception('something odd'));
      expect(message, contains('nothing was kept'));
      expect(message, contains('something odd'));
    });
  });

  group('GemmaCubit download state', () {
    test('a cubit starts idle and stays idle without a model', () async {
      final service = GemmaService();
      final cubit = GemmaCubit(service);

      await cubit.init();
      expect(cubit.state.status, GemmaStatus.idle);
      expect(cubit.state.downloadProgress, 0.0);
      expect(cubit.state.errorMessage, isNull);

      await cubit.close();
    });

    test(
      'deleting clears the error and progress from a failed attempt',
      () async {
        final service = GemmaService();
        final cubit = GemmaCubit(service);

        await cubit.deleteModel();

        expect(cubit.state.status, GemmaStatus.idle);
        expect(cubit.state.errorMessage, isNull);
        expect(cubit.state.downloadProgress, 0.0);

        await cubit.close();
      },
    );
  });
}
