# 1.2.0
- ## 1.2.0-dev.4
    - Added cancel download feature as requested in issue [#14](https://github.com/abdallah-odeh/flutter_file_downloader/issues/14)

- ## 1.2.0-dev.3
    - Improved logic in extracting file name from URL & user input [#23](https://github.com/abdallah-odeh/flutter_file_downloader/issues/23) thanks to [plabon](https://github.com/plabon)

- ## 1.2.0-dev.2

    - Fixed a bug where if an exception occurred at the first step (requesting permission) the Download Future does not end
    - Added support to pass headers with download file request
    - Added exception handler to avoid app crash and rethrow the exception to flutter when file name is invalid