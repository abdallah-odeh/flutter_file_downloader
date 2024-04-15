part of 'flutter_file_downloader.dart';

enum NotificationType {
  ///this will show all download notifications, progress, failed, completed
  ///basically keep the user notified about the download status
  all,

  ///this type will only notify the user about the download progress
  ///when the download is completed user will not get notified
  progressOnly,

  ///this type will only notify the user about the download result
  ///user will only be notified when download is completed, either succeed or failed
  completionOnly,

  ///this will completely suppress notifications,
  ///this type require a permission added in your manifest
  ///<uses-permission android:name="android.permission.DOWNLOAD_WITHOUT_NOTIFICATION" />
  ///if this permission is not your AndroidManifest file then the download will fail and give you an exception
  disabled,
}
