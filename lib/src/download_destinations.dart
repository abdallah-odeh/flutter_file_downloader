part of 'flutter_file_downloader.dart';

enum DownloadDestinations {
  ///this indicates the shared Downloads folder in the device,
  ///this is where the user expects to find the downloaded file
  ///for example, if the user clicked download on a document,
  ///usually he would open the downloads folder in his device
  ///expected output: /storage/emulated/0/Download/YOUR_FILE
  publicDownloads,

  ///this indicates the app-specific documents folder,
  ///this might be used to download temporary files
  ///or unintentionally downloaded files,
  ///for example if the user clicked a video to save offline
  appFiles,
}
