import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = '';
  final TextEditingController url = TextEditingController(
    text:
        'https://helpx.adobe.com/content/dam/help/en/photoshop/using/convert-color-image-black-white/jcr_content/main-pars/before_and_after/image-before/Landscape-Color.jpg',
  );
  final TextEditingController name = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter file downloader example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_status.isNotEmpty) ...[
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: url,
                decoration: const InputDecoration(label: Text('Url*')),
              ),
              TextField(
                controller: name,
                decoration: const InputDecoration(label: Text('File name')),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () async {
                final file = await FileDownloader.downloadFile(
                    url: url.text.trim(),
                    name: name.text.trim(),
                    onProgress: (name, progress) {
                      setState(() => _status = 'Progress: $progress%');
                    },
                    onDownloadCompleted: (path) {
                      setState(() => _status = 'File downloaded to: $path%');
                    },
                    onDownloadError: (error) {
                      setState(() => _status = 'Download error: $error%');
                    });
                print('file path: ${file?.path}');
              }, child: const Text('Download')),
            ],
          ),
        ),
      ),
    );
  }
}
