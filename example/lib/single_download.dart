import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_file_downloader_example/sesstion_settings.dart';

class SingleDownloadScreen extends StatefulWidget {
  const SingleDownloadScreen({Key? key}) : super(key: key);

  @override
  State<SingleDownloadScreen> createState() => _SingleDownloadScreenState();
}

class _SingleDownloadScreenState extends State<SingleDownloadScreen> {
  double? _progress;
  String _status = '';
  final SessionSettings settings = SessionSettings();
  final TextEditingController name = TextEditingController();
  final TextEditingController subPath = TextEditingController();
  final TextEditingController url = TextEditingController(
    text: 'https://research.nhm.org/pdfs/10840/10840-002.pdf',
    // 'http://www.africau.edu/images/default/sample.pdf',
    // 'https://helpx.adobe.com/content/dam/help/en/photoshop/using/convert-color-image-black-white/jcr_content/main-pars/before_and_after/image-before/Landscape-Color.jpg',
  );

  int? _downloadId;

  String? imageToWrite = 'burger1.webp';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_status.isNotEmpty) ...[
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 16),
            ],
            if (_progress != null) ...[
              CircularProgressIndicator(
                value: _progress! / 100,
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: url,
              decoration: const InputDecoration(labelText: 'Url*'),
            ),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'File name'),
            ),
            TextField(
              controller: subPath,
              decoration: const InputDecoration(
                labelText: 'Sub directories',
                hintText: 'mFiles/dir1/',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: _onDownloadFilePressed,
                    child: const Text('Download')),
                if (_downloadId != null) ...[
                  const SizedBox(width: 10),
                  ElevatedButton(
                      onPressed: _onCancelDownloadPressed,
                      child: const Text('Cancel')),
                ]
              ],
            ),
            const SizedBox(height: 32),
            DropdownButton<String>(
                value: imageToWrite,
                items: const [
                  DropdownMenuItem(
                      child: Text('burger1.webp'), value: 'burger1.webp'),
                  DropdownMenuItem(
                      child: Text('burger2.jpg'), value: 'burger2.jpg'),
                  DropdownMenuItem(
                      child: Text('dictionary.pdf'), value: 'dictionary.pdf'),
                ],
                onChanged: (value) {
                  setState(() => imageToWrite = value);
                }),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _onWriteFilePressed,
                child: const Text('Write image to storage')),
          ],
        ),
      ),
    );
  }

  void _onDownloadFilePressed() async {
    FileDownloader.downloadFile(
        // url: 'https://odeh-bros.com/dummy-link/file.pdf',
        url: url.text.trim(),
        // url: 'https://odeh-bros.com/dummy-link/file.pdf',
        name: name.text.trim(),
        // headers: {'Header': 'Test'},
        subPath: subPath.text.trim(),
        downloadDestination: settings.downloadDestination,
        notificationType: settings.notificationType,
        downloadService: DownloadService.httpConnection,
        onDownloadRequestIdReceived: (id) {
          print('DOWNLOAD: $id');
          setState(() => _downloadId = id);
        },
        onProgress: (name, progress) {
          print('PROG: $progress');
          setState(() {
            _progress = progress;
            _status = 'Progress: $progress%';
          });
        },
        onDownloadCompleted: (path) {
          print('DOWNLOAD COMPLETED $path');
          setState(() {
            _downloadId = null;
            _progress = null;
            _status = 'File downloaded to: $path';
          });
        },
        onDownloadError: (error) {
          setState(() {
            _progress = null;
            _status = 'Download error: $error';
          });
        }).then((file) {
      debugPrint('file path: ${file?.path}');
    });
  }

  void _onCancelDownloadPressed() async {
    final canceled = await FileDownloader.cancelDownload(_downloadId!);
    print('Canceled: $canceled');
  }

  void _onWriteFilePressed() async {
    if (imageToWrite?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select image name to write as a file'),
        ),
      );
      return;
    }
    final extension = imageToWrite!.split('.').last;
    String content;

    // List<int> imageBytes = widget.fileData.readAsBytesSync();
    // print(imageBytes);
    // String base64Image = base64Encode(imageBytes);

    final bytes = await rootBundle.load('assets/$imageToWrite');
    final buffer = bytes.buffer;
    content = base64.encode(Uint8List.view(buffer));

    FileDownloader.writeFile(
        content: content,
        extension: extension,
        fileName: name.text.trim(),
        subPath: subPath.text.trim(),
        downloadDestination: settings.downloadDestination,
        onProgress: (name, progress) {
          print('PROG: $progress');
          setState(() {
            _progress = progress;
            _status = 'Progress: $progress%';
          });
        },
        onCompleted: (path) {
          print('WRITE COMPLETED $path');
          setState(() {
            _downloadId = null;
            _progress = null;
            _status = 'File written to: $path';
          });
        },
        onError: (error) {
          setState(() {
            _progress = null;
            _status = 'Write file error: $error';
          });
        }).then((file) {
      debugPrint('file path: ${file?.path}');
    });
  }
}
