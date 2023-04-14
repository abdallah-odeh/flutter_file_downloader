import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'download_callbacks.dart';

part 'download_task.dart';

///FlutterFileDownloader core file that handles native calls
class FileDownloader {
  static FileDownloader? _instance;

  static const int _upperLimitParallelDownloads = 25;
  static int _maximumParallelDownloads = _upperLimitParallelDownloads;
  static int _taskID = 0;
  static bool _enableLog = false;
  final Map<int, _DownloadTask> _processingDownloadings = {};
  final List<_DownloadTask> _waitingDownloads = [];

  static const _platform = MethodChannel('com.abdallah.libs/file_downloader');
  final Map<int, _DownloadTask> _downloadTasks = {};

  FileDownloader._() {
    _platform.setMethodCallHandler(_methodCallHandler);
  }

  factory FileDownloader({
    final bool enableLog = false,
    final int maximumParallelDownloads = _upperLimitParallelDownloads,
  }) {
    setMaximumParallelDownloads(maximumParallelDownloads);
    setLogEnabled(enableLog);
    return _instance ??= FileDownloader._();
  }

  ///[maximumParallelDownloads]
  ///if this is not set, the default is [_upperLimitParallelDownloads]
  ///by using this method, you can limit the parallel downloads
  ///for example, if you set this value to 10
  ///and requested to download 20 files at the same time
  ///the files will be downloaded in two batches, 10 files each
  static void setMaximumParallelDownloads(final int maximumParallelDownloads) {
    if (maximumParallelDownloads > _upperLimitParallelDownloads) {
      debugPrint(
          'Setting the maximum parallel download to $maximumParallelDownloads is invalid, because the upper limit is $_upperLimitParallelDownloads, this is set to 25 to help you managing device resources');
      _maximumParallelDownloads = _upperLimitParallelDownloads;
    } else if (maximumParallelDownloads <= 0) {
      debugPrint(
          'Setting the maximum parallel download to $maximumParallelDownloads is invalid, because the lower limit is 1, using default $_upperLimitParallelDownloads');
      _maximumParallelDownloads = 1;
    } else {
      _maximumParallelDownloads = maximumParallelDownloads;
    }
  }

  ///[enabled]
  ///To print logs for downloading status & callbacks
  static void setLogEnabled(final bool enabled) => _enableLog = enabled;

  ///[url] the file url you want to download
  ///[name] the file name after download, this will be file name inside your dowloads directory
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
    return FileDownloader()
        ._downloadFile(
          url: url,
          name: name,
          onProgress: onProgress,
          onDownloadCompleted: onDownloadCompleted,
          onDownloadError: onDownloadError,
        )
        .catchError((error) => throw error);
  }

  ///[urls] a list of urls to files to be downloaded
  ///[onAllDownloaded] this callback will be triggered once all files downloaded are done
  ///                   note that some of the files might fail downloading
  ///                   and the files will be in the same order of the urls
  ///                   a filed to download file will be null at it's index
  static Future<List<File?>> downloadFiles({
    required final List<String> urls,
    final bool isParallel = true,
    final VoidCallback? onAllDownloaded,
  }) async {
    if (isParallel) {
      final result = <int, File?>{};
      final tasks = List<bool>.generate(urls.length, (_) => false);
      final completer = Completer();
      for (int i = 0; i < urls.length; i++) {
        result[i] = null;
        downloadFile(
            url: urls[i],
            onDownloadCompleted: (path) {
              result[i] = File(path);
              tasks[i] = true;
              if (!tasks.contains(false)) completer.complete();
            },
            onDownloadError: (error) {
              tasks[i] = true;
              if (!tasks.contains(false)) completer.complete();
            }).catchError((error) {
          tasks[i] = true;
          if (!tasks.contains(false)) completer.complete();
          return null;
        });
      }
      await completer.future;
      onAllDownloaded?.call();
      return result.values.toList();
    } else {
      final List<File?> result = [
        for (final url in urls)
          await downloadFile(url: url).catchError((error) => null),
      ];
      onAllDownloaded?.call();
      return result;
    }
  }

  Future<File?> _downloadFile({
    required final String url,
    final String? name,
    final OnProgress? onProgress,
    final OnDownloadCompleted? onDownloadCompleted,
    final OnDownloadError? onDownloadError,
  }) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      debugPrint(
          '[flutter_file_downloader] this plugin currently supports only android & iOS platforms');
      return Future.value(null);
    }
    if (!(Uri.tryParse(url)?.hasAbsolutePath ?? false)) {
      throw Exception(
          'URL is not valid, "$url" is not a valid url, please double check it then try again');
    }
    final task = _DownloadTask(
      url: url.trim(),
      name: name?.trim(),
      callbacks: DownloadCallbacks(
        onProgress: onProgress,
        onDownloadCompleted: onDownloadCompleted,
        onDownloadError: onDownloadError,
      ),
    );
    task.key = (++_taskID);
    _queueTask(task);
    _downloadTasks[task.key] = task;
    try {
      final result = await _platform.invokeMethod('downloadFile', {
        'url': url.trim(),
        'key': task.key.toString(),
        if (name?.trim().isNotEmpty ?? false) 'name': name!.trim(),
        if (onProgress != null) 'onprogress_named': 'valid function',
        'ondownloadcompleted': 'valid function',
        if (onDownloadError != null) 'ondownloaderror': 'valid function',
      });
      if (result is String &&
          result.isNotEmpty &&
          result.toLowerCase().startsWith('/storage/')) {
        return File(result);
      }
      print('RES: $result');
    } catch (e) {
      debugPrint('downloadFile error: $e');
    }
    return Future.value(null);
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    final id = call.arguments['id'].toString();
    final key = int.parse(call.arguments['key'].toString());

    switch (call.method) {
      case 'onIDReceived':
        final key = call.arguments['key']?.toString();
        _downloadTasks[key]?.id = id;
        break;
      case 'onProgress':
        _log(
            'File ${call.arguments['name']} is ${call.arguments['progress']}% done');
        _downloadTasks[key]?.callbacks.onProgress?.call(
              call.arguments['name'],
              call.arguments['progress'],
            );
        break;
      case 'onDownloadCompleted':
        _log(
            'Task ${call.arguments['key']} is downloaded in: ${call.arguments['path']}');
        _downloadTasks[key]?.notifyDownloaded();
        _downloadTasks[key]
            ?.callbacks
            .onDownloadCompleted
            ?.call(call.arguments['path']);
        _downloadTasks.remove(key);
        break;
      case 'onDownloadError':
        _log(
            'Task ${call.arguments['key']} failed to download: ${call.arguments['error']}');
        _downloadTasks[key]
            ?.callbacks
            .onDownloadError
            ?.call(call.arguments['error']);
        _downloadTasks.remove(key);
        break;
      default:
        throw Exception('Could not find a callback for ${call.method}');
    }
  }

  void _log(final String message) {
    if (!_enableLog) return;
    debugPrint(message);
  }

  void _queueTask(final _DownloadTask task) {
    if (_processingDownloadings.length < _maximumParallelDownloads) {
      _log('Start downloading task no ${task.key}');
      _processingDownloadings[_taskID] = task;
      task.waitDownload().whenComplete(() {
        _log(
            'Download task ${task.key} is done, checking for waiting tasks...');
        _processingDownloadings.remove(task.key);
        _startWaitingTask();
      });
    } else {
      _log(
          'Task ${task.key} is quened because maximum parallel download is reached');
      _waitingDownloads.add(task);
    }
  }

  void _startWaitingTask() {
    if (_waitingDownloads.isEmpty) return;
    _queueTask(_waitingDownloads.removeAt(0));
  }

  int get maximumParallelDownloads => _maximumParallelDownloads;

  bool get isLogEnabled => _enableLog;
}
