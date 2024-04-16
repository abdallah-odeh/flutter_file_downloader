// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://docs.flutter.dev/cookbook/testing/integration/introduction

import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_file_downloader_example/main.dart';
import 'package:flutter_file_downloader_example/preferences_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late String downloadPath;

  group('Single download', () {
    setUp(() {
      downloadPath = 'https://research.nhm.org/pdfs/10840/10840-002.pdf';
    });

    testWidgets(
      'Valid url must be downloaded without any issues',
      (tester) async {
        await PreferencesManager().initialize();

        runApp(const MyApp());
        await tester.pumpAndSettle();

        final file = await FileDownloader.downloadFile(url: downloadPath);
        expect(
          file != null,
          true,
          reason: 'Simple download must never failed',
        );

        expect(
          await file!.exists(),
          true,
          reason: 'File must be downloaded and exists in it\'s path',
        );
      },
    );
  });
}
