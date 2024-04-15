part of 'flutter_file_downloader.dart';

enum DownloadService {
  ///this is the recommended way to download any file in android OS
  ///DEFAULT value unless a method type other than GET
  ///pros:
  /// - Simpler & way faster
  /// - Operated by the OS itself
  /// - Does not need any notifications permissions
  ///cons:
  /// - Does not support downloading via different method type such as POST
  /// - Does not support reading file content
  downloadManager,

  ///more flexible way to download or get file content from the internet
  ///pros:
  /// - More accurate when tracking the download progress
  /// - Ability to get mime type from response header
  /// - Ability to download files over POST request
  ///cons:
  /// - Needs POST_NOTIFICATIONS permission to show notifications
  /// - A lot slower than [DownloadManager]
  httpConnection,
}
