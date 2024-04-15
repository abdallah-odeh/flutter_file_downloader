part of 'flutter_file_downloader.dart';

///The download task model to store some unique vars
class _DownloadTask {
  late final String id;
  late final int key;
  final String url;
  final String? name;
  final String? subPath;
  final NotificationType notificationType;
  final DownloadDestinations downloadDestination;
  final DownloadCallbacks callbacks;
  final DownloadService downloadService;
  final DownloadRequestMethodType methodType;
  final Map<String, String> headers;
  final Completer<bool> _completer;

  _DownloadTask({
    required this.url,
    required this.callbacks,
    this.name,
    this.subPath,
    this.notificationType = NotificationType.progressOnly,
    this.downloadDestination = DownloadDestinations.publicDownloads,
    this.downloadService = DownloadService.downloadManager,
    this.methodType = DownloadRequestMethodType.get,
    this.headers = const <String, String>{},
  }) : //key = DateTime.now().millisecondsSinceEpoch.toString(),
        _completer = Completer<bool>();

  bool get isDownloaded => _completer.isCompleted;

  //To download until this specific task is fully downloaded
  Future waitDownload() => _completer.future;

  //To notify observers that this task is fully downloaded
  void notifyCompleted(final bool success) => _completer.complete(success);

  Map<String, dynamic> toMap() {
    // append initial values
    final result = <String, dynamic>{
      'url': url.trim(),
      'key': key.toString(),
      'notifications': notificationType.name,
      'download_destination': downloadDestination.name,
      'download_service': downloadService.name,
      'method_type': methodType.name,
      'headers': headers,
    };

    // append callback functions
    result.addAll({
      'onidreceived': callbacks.onDownloadRequestIdReceived?.toString(),
      'onprogress_named': callbacks.onProgress?.toString(),
      'ondownloadcompleted': callbacks.onDownloadCompleted?.toString(),
      'ondownloaderror': callbacks.onDownloadError?.toString(),
    });

    // append file name if provided
    if (name?.trim().isNotEmpty ?? false) {
      result['name'] = name!.trim();
    }

    // append sub path if provided
    if (subPath?.trim().isNotEmpty ?? false) {
      result['subPath'] = subPath!.trim();
    }

    return result;
  }
}
