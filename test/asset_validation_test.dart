import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<String> awsIcons = [
    "aws-lambda.svg",
    "aws-ec2.svg",
    "aws-simple-storage-service.svg",
    "aws-dynamodb.svg",
    "aws-api-gateway.svg",
    "aws-identity-and-access-management.svg",
    "aws-cloudwatch.svg",
    "aws-rds.svg",
  ];

  final List<String> azureIcons = [
    "azure-virtual-machine.svg",
    "azure-function-apps.svg",
    "azure-cosmos-db.svg",
    "azure-active-directory.svg",
    "azure-sql-database.svg",
    "azure-storage-accounts.svg",
    "azure-virtual-networks.svg",
    "azure-app-services.svg",
  ];

  final List<String> gcpIcons = [
    "gcp-compute-engine.svg",
    "gcp-cloud-functions.svg",
    "gcp-cloud-storage.svg",
    "gcp-bigquery.svg",
    "gcp-cloud-run.svg",
    "gcp-cloud-sql.svg",
    "gcp-identity-and-access-management.svg",
    "gcp-pubsub.svg",
  ];

  group('Asset Validation Tests', () {
    testWidgets('Verify all toolbar icons exist and are valid SVGs', (WidgetTester tester) async {
      final allIcons = [
        ...awsIcons.map((e) => 'assets/icons/aws-icons/$e'),
        ...azureIcons.map((e) => 'assets/icons/azure-icons/$e'),
        ...gcpIcons.map((e) => 'assets/icons/gcp-icons/$e'),
      ];

      for (final path in allIcons) {
        // Physical file check
        final file = File(path);
        expect(file.existsSync(), true, reason: 'File NOT found: $path');

        // SVG load check
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
