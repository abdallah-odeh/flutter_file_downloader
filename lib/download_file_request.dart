class DownloadFileRequest {
  final String url;
  final Map<String, String> headers;

  DownloadFileRequest(this.url, {this.headers = const <String, String>{}});
}
