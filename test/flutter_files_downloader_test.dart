import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_files_downloader/flutter_files_downloader.dart';
import 'package:flutter_files_downloader/flutter_files_downloader_platform_interface.dart';
import 'package:flutter_files_downloader/flutter_files_downloader_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterFilesDownloaderPlatform
    with MockPlatformInterfaceMixin
    implements FlutterFilesDownloaderPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterFilesDownloaderPlatform initialPlatform = FlutterFilesDownloaderPlatform.instance;

  test('$MethodChannelFlutterFilesDownloader is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterFilesDownloader>());
  });

  test('getPlatformVersion', () async {
    FlutterFilesDownloader flutterFilesDownloaderPlugin = FlutterFilesDownloader();
    MockFlutterFilesDownloaderPlatform fakePlatform = MockFlutterFilesDownloaderPlatform();
    FlutterFilesDownloaderPlatform.instance = fakePlatform;

    expect(await flutterFilesDownloaderPlugin.getPlatformVersion(), '42');
  });
}
