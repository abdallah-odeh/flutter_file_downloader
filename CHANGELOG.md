## 1.2.2

- Fixed duplicate call for onProgress [#44](https://github.com/abdallah-odeh/flutter_file_downloader/issues/44)

## 1.2.2-dev.1

- Fixed binding a broadcast in new android 14 issue

## 1.2.1

- Fixed crash exception when file URL does not contain file extension

## 1.2.0

- Cancel download feature as requested in issue [#14](https://github.com/abdallah-odeh/flutter_file_downloader/issues/14)
- Support passing headers with download file request [#16](https://github.com/abdallah-odeh/flutter_file_downloader/issues/16)
- Improved logic in extracting file name from URL & user input [#23](https://github.com/abdallah-odeh/flutter_file_downloader/issues/23) thanks to [plabon](https://github.com/plabon)
- Fixed a bug where if an exception occurred at the first step (requesting permission) the Download Future does not end
- Added exception handler to avoid app crash and rethrow the exception to flutter when file name is invalid