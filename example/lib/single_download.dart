import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

class SingleDownloadScreen extends StatefulWidget {
  const SingleDownloadScreen({Key? key}) : super(key: key);

  @override
  State<SingleDownloadScreen> createState() => _SingleDownloadScreenState();
}

class _SingleDownloadScreenState extends State<SingleDownloadScreen> {
  double? _progress;
  String _status = '';
  final TextEditingController name = TextEditingController();
  final TextEditingController url = TextEditingController(
    text:
    // 'http://www.africau.edu/images/default/sample.pdf',
    'https://helpx.adobe.com/content/dam/help/en/photoshop/using/convert-color-image-black-white/jcr_content/main-pars/before_and_after/image-before/Landscape-Color.jpg',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
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
              decoration: const InputDecoration(label: Text('Url*')),
            ),
            TextField(
              controller: name,
              decoration: const InputDecoration(label: Text('File name')),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () async {
              FileDownloader.downloadFile(
                  url: url.text.trim(),
                  name: name.text.trim(),
                  onProgress: (name, progress) {
                    setState(() {
                      _progress = progress;
                      _status = 'Progress: $progress%';
                    });
                  },
                  onDownloadCompleted: (path) {
                    setState(() {
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
            }, child: const Text('Download')),
          ],
        ),
      ),
    );
  }
}
