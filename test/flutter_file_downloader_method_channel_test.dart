import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_file_downloader/flutter_file_downloader_method_channel.dart';

void main() {
  MethodChannelFlutterFileDownloader platform = MethodChannelFlutterFileDownloader();
  const MethodChannel channel = MethodChannel('flutter_file_downloader');

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
