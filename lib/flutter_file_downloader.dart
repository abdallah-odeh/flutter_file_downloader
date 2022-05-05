import 'dart:io';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'download_callbacks.dart';

///FlutterFileDownloader core file that handles native calls
class FileDownloader {
  static FileDownloader? _instance;

  static const platform = MethodChannel('com.abdallah.libs/file_downloader');
  final Map<String, DownloadCallbacks> _callbacksById = {};
  final Map<String, DownloadCallbacks> _pendingCallbacks = {};

  FileDownloader._() {
    platform.setMethodCallHandler(_methodCallHandler);
  }

  factory FileDownloader() => _instance ??= FileDownloader._();

  ///[url]: the file url you want to download
  ///[name]: the file name after download, this will be file name inside your dowloads directory
  ///        if this was null, then the last segment of the url will be used as the name
  ///        the name can be written with the extension, if not, the extension will be extracted from the url
  ///[onProgress] when the download progress change, you can update your UI or do anything you want
  ///             Note, some devices or urls jumps from 0 to 100 in one step
  ///[onDownloadCompleted] When the download is complete, this callback will be fired holding the file path
  ///[onDownloadError] When something unexpected happens, this callback will be fired
  static Future<File?> downloadFile({
    required final String url,
    final String? name,
    final OnProgress? onProgress,
    final OnDownloadCompleted? onDownloadCompleted,
    final OnDownloadError? onDownloadError,
  }) async {
    return FileDownloader()._downloadFile(
      url: url,
      name: name,
      onProgress: onProgress,
      onDownloadCompleted: onDownloadCompleted,
      onDownloadError: onDownloadError,
    );
  }

  Future<File?> _downloadFile({
    required final String url,
    final String? name,
    final OnProgress? onProgress,
    final OnDownloadCompleted? onDownloadCompleted,
    final OnDownloadError? onDownloadError,
  }) async {
    if (!Platform.isAndroid) {
      debugPrint(
          '[flutter_file_downloader] this plugin currently supports only android platform');
      return null;
    }
    if (!(Uri.tryParse(url)?.hasAbsolutePath ?? false)) {
      throw Exception(
          'URL is not valid, "$url" is not a valid url, please double check it then try again');
    }
    _pendingCallbacks['$url|${DateTime.now().millisecondsSinceEpoch}'] =
        DownloadCallbacks(
      onProgress: onProgress,
      onDownloadCompleted: onDownloadCompleted,
      onDownloadError: onDownloadError,
    );
    try {
      final result = await platform.invokeMethod('downloadFile', {
        'url': url.trim(),
        if (name?.trim().isNotEmpty ?? false) 'name': name!.trim(),
        if (onProgress != null) 'onprogress_named': 'valid function',
        if (onDownloadCompleted != null)
          'ondownloadcompleted': 'valid function',
        if (onDownloadError != null) 'ondownloaderror': 'valid function',
      });
      if (result is String &&
          result.isNotEmpty &&
          result.toLowerCase().startsWith('/storage/')) {
        return File(result);
      }
    } catch (e) {
      debugPrint('downloadFile error: $e');
    }
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    final id = call.arguments["id"].toString();

    switch (call.method) {
      case 'onIDReceived':
        final url = call.arguments['url']?.toString();
        DownloadCallbacks? callbacks;
        for (final key in _pendingCallbacks.keys) {
          if (key.toLowerCase().startsWith(url?.toLowerCase() ?? 'NO')) {
            callbacks = _pendingCallbacks.remove(key);
            break;
          }
        }
        _callbacksById[id] = callbacks ?? DownloadCallbacks();
        break;
      case 'onProgress':
        _callbacksById[id]?.onProgress?.call(
              call.arguments["name"],
              call.arguments["progress"],
            );
        break;
      case 'onDownloadCompleted':
        _callbacksById[id]?.onDownloadCompleted?.call(call.arguments["path"]);
        _callbacksById.remove(id);
        break;
      case 'onDownloadError':
        _callbacksById[id]?.onDownloadError?.call(call.arguments["error"]);
        _callbacksById.remove(id);
        break;
      default:
        throw Exception('Could not find a callback for ${call.method}');
    }
  }
}
