import 'package:flutter_file_downloader/flutter_file_downloader.dart';

class SessionSettings {
  static SessionSettings? _instance;
  var _notificationType = NotificationType.progressOnly;
  var _downloadDestination = DownloadDestinations.publicDownloads;
  var _maximumParallelDownloads = FileDownloader().maximumParallelDownloads;

  SessionSettings._();

  factory SessionSettings() => _instance ??= SessionSettings._();

  void setNotificationType(NotificationType notificationType) =>
      _notificationType = notificationType;

  void setDownloadDestination(DownloadDestinations downloadDestination) =>
      _downloadDestination = downloadDestination;

  void setMaximumParallelDownloads(int maximumParallelDownloads) {
    if (maximumParallelDownloads <= 0) return;
    _maximumParallelDownloads = maximumParallelDownloads;
    FileDownloader.setMaximumParallelDownloads(maximumParallelDownloads);
  }

  NotificationType get notificationType => _notificationType;

  DownloadDestinations get downloadDestination => _downloadDestination;

  int get maximumParallelDownloads => _maximumParallelDownloads;
}
