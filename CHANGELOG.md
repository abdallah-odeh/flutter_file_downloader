## 1.2.0-dev.2

- Fixed a bug where if an exception occurred at the first step (requesting permission) the Download Future does not end
- Added support to pass headers with download file request
- Added exception handler to avoid app crash and rethrow the exception to flutter when file name is invalid