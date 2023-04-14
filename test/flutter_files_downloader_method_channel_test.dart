import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_files_downloader/flutter_files_downloader_method_channel.dart';

void main() {
  MethodChannelFlutterFilesDownloader platform = MethodChannelFlutterFilesDownloader();
  const MethodChannel channel = MethodChannel('flutter_files_downloader');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
