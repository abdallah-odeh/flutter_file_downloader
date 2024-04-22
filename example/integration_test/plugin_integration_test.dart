// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://docs.flutter.dev/cookbook/testing/integration/introduction

import 'dart:async';

import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_file_downloader_example/main.dart';
import 'package:flutter_file_downloader_example/preferences_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await PreferencesManager().initialize();
  late String downloadPath;

  group('Single download', () {
    setUp(() {
      downloadPath = 'https://research.nhm.org/pdfs/10840/10840-002.pdf';
    });

    group(
      'Download Manager service',
      () {
        testWidgets(
          'File must be downloaded in Downloads/',
          (tester) async {
            await tester.pumpWidget(const MyApp());

            final file = await FileDownloader.downloadFile(url: downloadPath);
            expect(
              file != null,
              true,
              reason: 'Simple download must never failed',
            );

            expect(
              await file!.exists(),
              true,
              reason: 'File must be downloaded and exists under Downloads/',
            );
          },
        );
        testWidgets(
          'File must be downloaded in AppData/',
          (tester) async {
            await tester.pumpWidget(const MyApp());

            final file = await FileDownloader.downloadFile(
              url: downloadPath,
              downloadDestination: DownloadDestinations.appFiles,
            );
            expect(
              file != null,
              true,
              reason: 'Simple download must never failed',
            );

            expect(
              await file!.exists(),
              true,
              reason: 'File must be downloaded and exists under AppData/',
            );
          },
        );

        testWidgets(
          'SubPath feature test',
          (tester) async {
            await tester.pumpWidget(const MyApp());

            const String subPath = 'flutter_file_downloader/integration-test/';

            final file = await FileDownloader.downloadFile(
              url: downloadPath,
              subPath: subPath,
            );
            expect(
              file != null,
              true,
              reason: 'Simple download must never failed',
            );

            expect(
              file!.path.contains(subPath),
              true,
              reason: 'File path must contain the subPath $subPath',
            );

            expect(
              await file.exists(),
              true,
              reason:
                  'File must be downloaded and exists under Downloads/$subPath',
            );
          },
        );
        testWidgets(
          'File must be renamed after download',
          (tester) async {
            await tester.pumpWidget(const MyApp());

            final String randomName =
                'test-file-${DateTime.now().millisecondsSinceEpoch}';

            final file = await FileDownloader.downloadFile(
              url: downloadPath,
              name: randomName,
            );

            expect(
              file != null,
              true,
              reason: 'Simple download must never failed',
            );

            final realFileName = file!.path.split('/').last;

            expect(
              realFileName.startsWith(randomName),
              true,
              reason: 'Filename must be $randomName but it\'s $realFileName',
            );

            expect(
              await file.exists(),
              true,
              reason: 'File must be downloaded and exists under Downloads/',
            );
          },
        );

        group('Callbacks test cases', () {
          testWidgets(
            'Test onProgress callback is triggered',
            (tester) async {
              await tester.pumpWidget(const MyApp());

              var callbackTriggered = false;

              await FileDownloader.downloadFile(
                url: downloadPath,
                onProgress: (name, progress) {
                  callbackTriggered = true;
                },
              );

              expect(
                callbackTriggered,
                true,
                reason:
                    'onProgress must be triggered whenever download progress change',
              );
            },
          );

          testWidgets(
            'Test onDownloadCompleted callback is triggered',
            (tester) async {
              await tester.pumpWidget(const MyApp());

              var callbackTriggered = false;

              await FileDownloader.downloadFile(
                url: downloadPath,
                onDownloadCompleted: (path) {
                  callbackTriggered = true;
                },
              );

              expect(
                callbackTriggered,
                true,
                reason:
                    'onDownloadCompleted must be triggered when download is completed successfully',
              );
            },
          );

          testWidgets(
            'Test onDownloadError callback is triggered when passing an invalid URL',
            (tester) async {
              await tester.pumpWidget(const MyApp());

              var callbackTriggered = false;

              await FileDownloader.downloadFile(
                url: 'this is a sample of an invalid URL!',
                onDownloadError: (error) {
                  callbackTriggered = true;
                },
              );

              expect(
                callbackTriggered,
                true,
                reason:
                    'onDownloadError must be triggered when an invalid URL is passed',
              );
            },
          );

          testWidgets(
            'Test onDownloadError callback is triggered when passing a wrong URL',
            (tester) async {
              await tester.pumpWidget(const MyApp());

              var callbackTriggered = false;

              await FileDownloader.downloadFile(
                url: 'https://odeh-bros.com/dummy-link/file.pdf',
                onDownloadError: (error) {
                  callbackTriggered = true;
                },
              );

              expect(
                callbackTriggered,
                true,
                reason:
                    'onDownloadError must be triggered when a wrong URL is passed',
              );
            },
          );
        });

        testWidgets(
          'Cancel download should pass',
          (tester) async {
            await tester.pumpWidget(const MyApp());

            final Completer<int> downloadIdCompleter = Completer<int>();

            // downloadPath = 'https://research.nhm.org/pdfs/10840/10840.pdf';
            FileDownloader.downloadFile(
              url: downloadPath,
              onDownloadRequestIdReceived: downloadIdCompleter.complete,
            ).then((value) {
              fail(
                  'Download has completed without firing the downloadIdReceived callback');
            });

            final int downloadId = await downloadIdCompleter.future;

            expect(
              downloadId > 0,
              true,
              reason: 'Download id must be a positive integer',
            );

            final canceled = await FileDownloader.cancelDownload(downloadId);

            expect(
              canceled,
              true,
              reason: 'Cancel download must succeed',
            );
          },
        );
      },
      // skip: true,
    );
    group('HTTPConnection service', () {
      late DownloadService downloadService;
      setUp(() {
        downloadService = DownloadService.httpConnection;
      });

      testWidgets(
        'File must be downloaded in Downloads/',
        (tester) async {
          await tester.pumpWidget(const MyApp());

          final file = await FileDownloader.downloadFile(
            url: downloadPath,
            downloadService: downloadService,
          );
          expect(
            file != null,
            true,
            reason: 'Simple download must never failed',
          );

          expect(
            await file!.exists(),
            true,
            reason: 'File must be downloaded and exists under Downloads/',
          );
        },
      );
      testWidgets(
        'File must be downloaded in AppData/',
        (tester) async {
          await tester.pumpWidget(const MyApp());

          final file = await FileDownloader.downloadFile(
            url: downloadPath,
            downloadService: downloadService,
            downloadDestination: DownloadDestinations.appFiles,
          );
          expect(
            file != null,
            true,
            reason: 'Simple download must never failed',
          );

          expect(
            await file!.exists(),
            true,
            reason: 'File must be downloaded and exists under AppData/',
          );
        },
      );

      testWidgets(
        'SubPath feature test',
        (tester) async {
          await tester.pumpWidget(const MyApp());

          const String subPath = 'flutter_file_downloader/integration-test/';

          final file = await FileDownloader.downloadFile(
            url: downloadPath,
            downloadService: downloadService,
            subPath: subPath,
          );
          expect(
            file != null,
            true,
            reason: 'Simple download must never failed',
          );

          expect(
            file!.path.contains(subPath),
            true,
            reason: 'File path must contain the subPath $subPath',
          );

          expect(
            await file.exists(),
            true,
            reason:
                'File must be downloaded and exists under Downloads/$subPath',
          );
        },
      );
      testWidgets(
        'File must be renamed after download',
        (tester) async {
          await tester.pumpWidget(const MyApp());

          final String randomName =
              'test-file-${DateTime.now().millisecondsSinceEpoch}';

          final file = await FileDownloader.downloadFile(
            url: downloadPath,
            downloadService: downloadService,
            name: randomName,
          );

          expect(
            file != null,
            true,
            reason: 'Simple download must never failed',
          );

          final realFileName = file!.path.split('/').last;

          expect(
            realFileName.startsWith(randomName),
            true,
            reason: 'Filename must be $randomName but it\'s $realFileName',
          );

          expect(
            await file.exists(),
            true,
            reason: 'File must be downloaded and exists under Downloads/',
          );
        },
      );

      group('Callbacks test cases', () {
        testWidgets(
          'Test onProgress callback is triggered',
          (tester) async {
            await tester.pumpWidget(const MyApp());

            var callbackTriggered = false;

            await FileDownloader.downloadFile(
              url: downloadPath,
              downloadService: downloadService,
              onProgress: (name, progress) {
                callbackTriggered = true;
              },
            );

            expect(
              callbackTriggered,
              true,
              reason:
                  'onProgress must be triggered whenever download progress change',
            );
          },
        );

        testWidgets(
          'Test onDownloadCompleted callback is triggered',
          (tester) async {
            await tester.pumpWidget(const MyApp());

            var callbackTriggered = false;

            final file = await FileDownloader.downloadFile(
              url: downloadPath,
              downloadService: downloadService,
              onDownloadCompleted: (path) {
                callbackTriggered = true;
              },
            );

            tester.printToConsole('Download is over, ${file?.path}');

            expect(
              callbackTriggered,
              true,
              reason:
                  'onDownloadCompleted must be triggered when download is completed successfully',
            );
          },
        );

        testWidgets(
          'Test onDownloadError callback is triggered when passing an invalid URL',
          (tester) async {
            await tester.pumpWidget(const MyApp());

            var callbackTriggered = false;

            await FileDownloader.downloadFile(
              url: 'this is a sample of an invalid URL!',
              downloadService: downloadService,
              onDownloadError: (error) {
                callbackTriggered = true;
              },
            );

            expect(
              callbackTriggered,
              true,
              reason:
                  'onDownloadError must be triggered when an invalid URL is passed',
            );
          },
        );

        testWidgets(
          'Test onDownloadError callback is triggered when passing a wrong URL',
          (tester) async {
            await tester.pumpWidget(const MyApp());

            var callbackTriggered = false;

            await FileDownloader.downloadFile(
              url: 'https://odeh-bros.com/dummy-link/file.pdf',
              downloadService: downloadService,
              onDownloadError: (error) {
                callbackTriggered = true;
              },
            );

            expect(
              callbackTriggered,
              true,
              reason:
                  'onDownloadError must be triggered when a wrong URL is passed',
            );
          },
        );
      });

      testWidgets(
        'Cancel download should pass',
        (tester) async {
          await tester.pumpWidget(const MyApp());

          final Completer<int> downloadIdCompleter = Completer<int>();

          // downloadPath = 'https://research.nhm.org/pdfs/10840/10840.pdf';
          FileDownloader.downloadFile(
            url: downloadPath,
            downloadService: downloadService,
            onDownloadRequestIdReceived: downloadIdCompleter.complete,
          ).then((value) {
            if (!downloadIdCompleter.isCompleted) {
              fail(
                  'Download has completed without firing the downloadIdReceived callback');
            }
          });

          final int downloadId = await downloadIdCompleter.future;

          expect(
            downloadId > 0,
            true,
            reason: 'Download id must be a positive integer',
          );

          final canceled = await FileDownloader.cancelDownload(downloadId);

          expect(
            canceled,
            true,
            reason: 'Cancel download must succeed',
          );
        },
      );
    });
  });
}
