# flutter_file_downloader

A simple flutter plugin that downloads all files types to downloads directory in all android devices.
When android 10 came out, privacy was changed in big way
and there are not enough info about it that are related to flutter,
so I came up with a simple ANDROID plugin to downloads any file type to downloads directory
Also it has callbacks and progress listeners with a very easy installation
Note: This plugin is not built for iOS, it will not effect it at all.

## Getting Started

Add the following line to your pubspec.yaml
  `flutter_file_downloader: ^1.0.0`

Next,
    add the library import to your dart file,
    `import 'package:flutter_file_downloader/flutter_file_downloader.dart';`

Last step,
    use the library easily in your code
    `FileDownloader().downloadFile(
        url: _YOUR DOWNLOAD URL_,
        name: **OPTIONAL**, _THE FILE NAME AFTER DOWNLOADING_,
        onProgress: (name, progress) {
          print('FILE $name HAS PROGRESS $progress');
        },
        onDownloadCompleted: (path) {
          print('FILE DOWNLOADED TO PATH: $path');
        },
        onDownloadError: (error) {
          print('DOWNLOAD ERROR: $error');
        });`

    **All callbacks can be null, you can simply call** `FileDownloader().downloadFile(YOUR_URL);`

Please if you found any bug or issue do not hesitate opening an issue on github
Also if you have any idea to enhance this plugin or add more features, feel free to **Pull request**
