typedef OnProgress = Function(String? fileName, double progress);
typedef OnDownloadCompleted = Function(String path);
typedef OnDownloadError = Function(String errorMessage);

class DownloadCallbacks {
  final OnProgress? onProgress;
  final OnDownloadCompleted? onDownloadCompleted;
  final OnDownloadError? onDownloadError;

  DownloadCallbacks({
    this.onProgress,
    this.onDownloadCompleted,
    this.onDownloadError,
  });

  @override
  String toString() {
    return 'DownloadCallbacks{onProgress: $onProgress, onDownloadCompleted: $onDownloadCompleted, onDownloadError: $onDownloadError}';
  }
}
