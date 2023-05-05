import 'package:flutter/material.dart';
import 'package:flutter_file_downloader_example/multiple_downloads.dart';
import 'package:flutter_file_downloader_example/preferences_manager.dart';
import 'package:flutter_file_downloader_example/settings.dart';

import 'single_download.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesManager().initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  late final TabController tabController =
      TabController(length: 3, vsync: this, initialIndex: 1);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ar'),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter file downloader example'),
        ),
        body: TabBarView(
          controller: tabController,
          children: const [
            SettingsScreen(),
            SingleDownloadScreen(),
            MultipleDownloads(),
          ],
        ),
        bottomNavigationBar: TabBar(
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
            Tab(icon: Icon(Icons.download_rounded), text: 'Single download'),
            Tab(icon: Icon(Icons.cloud_download), text: 'Bulk download'),
          ],
          controller: tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
        ),
      ),
    );
  }
}
