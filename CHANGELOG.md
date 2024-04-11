# Change Log

## [1.2.2] - TO BE PUBLISHED
### Fixed
- Fixed duplicate call for onProgress

## [1.2.2-dev.1] - 08-04-2024
### Fixed
- Fixed binding a broadcast in new android 14 issue

## [1.2.1] - 07-01-2024
### Fixed
- Fixed crash exception when file URL does not contain file extension

## [1.2.0] - 07-12-2023
### Added
- Cancel download feature as requested in issue [#14](https://github.com/abdallah-odeh/flutter_file_downloader/issues/14)
- Support passing headers with download file request [#16](https://github.com/abdallah-odeh/flutter_file_downloader/issues/16)

### Changed
- Improved logic in extracting file name from URL & user input [#23](https://github.com/abdallah-odeh/flutter_file_downloader/issues/23) thanks to [plabon](https://github.com/plabon)

### Fixed
- Fixed a bug where if an exception occurred at the first step (requesting permission) the Download Future does not end
- Added exception handler to avoid app crash and rethrow the exception to flutter when file name is invalid