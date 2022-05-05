# flutter_file_downloader

A simple flutter plugin that downloads all files types to downloads directory in all android devices.
When android 10 came out, privacy restrictions were changed in big way
and there are not enough flutter-related info about it,
so I came up with a simple ANDROID plugin to downloads any file type to downloads directory
Also it has callbacks and progress listeners with a very easy installation
Note: This plugin is not built for iOS, it will not effect it at all.

## Getting Started

First, make sure that you've added the permissions to your AndroidManifest.xml
```
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

Add the following line to your pubspec.yaml  
``` flutter_file_downloader: ^1.0.5```

Next,  
    add the library import to your dart file,  
```
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
```

Last step,  
    use the library easily in your code  
```
FileDownloader().downloadFile(
    url: _YOUR DOWNLOAD URL_,
    name: **OPTIONAL**, _THE FILE NAME AFTER DOWNLOADING_,
    onProgress: (String fileName, double progress) {
      print('FILE fileName HAS PROGRESS $progress');
    },
    onDownloadCompleted: (String path) {
      print('FILE DOWNLOADED TO PATH: $path');
    },
    onDownloadError: (String error) {
      print('DOWNLOAD ERROR: $error');
    });
```

**All callbacks are nullables, you can simply call** `FileDownloader().downloadFile(YOUR_URL);`

## Examples:
```
FileDownloader().downloadFile(
    url: "https://tinypng.com/images/social/website.jpg",
    name: "PANDA",
    onDownloadCompleted: (path) {
        final File file = File(path);
        //This will be the path of the downloaded file
    });
```
```
final File? file = await FileDownloader().downloadFile(
    url: "https://tinypng.com/images/social/developer-api.jpg",
    name: "ANOTHER PANDA.jpg");

print('FILE: ${file?.path}');
```

You can also track the progress if you want to add a progress bar
```
final File? file = await FileDownloader().downloadFile(
    url: "https://tinypng.com/images/social/developer-api.jpg",
    name: "ANOTHER PANDA.jpg",
    onProgress: (String fileName, double progress) {
        setState(() => _progress = progress);
    });

print('FILE: ${file?.path}');`
```

## Contributing
All contributions are welcome!

If you like this project then please click on the 🌟 it'll be appreciated or if you wanna add more epic stuff you can submite your pull request and it'll be gladly accepted 🙆‍♂️

or if you found any bug or issue do not hesitate opening an issue on github
