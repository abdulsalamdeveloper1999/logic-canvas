import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Asset Validation Tests', () {
    testWidgets('Verify all bundled SVG icons are valid', (WidgetTester tester) async {
      final List<String> categories = ['aws-icons', 'azure-icons', 'gcp-icons'];
      final List<String> allIconPaths = [];

      for (final category in categories) {
        final dir = Directory('assets/icons/$category');
        if (dir.existsSync()) {
          final files = dir.listSync().where((f) => f.path.endsWith('.svg'));
          for (final file in files) {
            allIconPaths.add(file.path);
          }
        }
      }

      debugPrint('Found ${allIconPaths.length} icons to validate.');

      for (final path in allIconPaths) {
        final file = File(path);
        expect(file.existsSync(), true, reason: 'File NOT found: $path');

        // SVG load check (sampling if there are too many, but here we try all)
        try {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SvgPicture.file(file),
              ),
            ),
          );
          await tester.pump();
        } catch (e) {
          fail('Failed to load SVG at $path: $e');
        }
      }
    });
  });
}
