import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_downloader/src/download_file_request.dart';

import 'download_callbacks.dart';

part 'download_destinations.dart';
part 'download_request_method_type.dart';
part 'download_service.dart';
part 'download_task.dart';
part 'notification_types.dart';

///FlutterFileDownloader core file that handles native calls
class FileDownloader {
  static FileDownloader? _instance;

  static const int _upperLimitParallelDownloads = 25;
  static int _maximumParallelDownloads = _upperLimitParallelDownloads;
  static int _taskID = 0;
  static bool _enableLog = false;
  final Map<int, _PluginTask> _processingDownloads = {};
  final List<_PluginTask> _waitingDownloads = [];

  static const _platform = MethodChannel('com.abdallah.libs/file_downloader');
  final Map<int, _PluginTask> _downloadTasks = {};

  FileDownloader._() {
    _platform.setMethodCallHandler(_methodCallHandler);
  }

  factory FileDownloader() {
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
  ///       if this was null, then the last segment of the url will be used as the name
  ///       the name can be written with the extension, if not, the extension will be extracted from the url
  ///[downloadDestination] the desired download location, this can either be public download directory (Default)
  ///                      or the app's private files directory
  ///[onDownloadRequestIdReceived] triggered when downloading service get the task and returns the
  ///                              new task id
  ///                              this callback must be used when wanting to cancel the download
  ///[onProgress] when the download progress change, you can update your UI or do anything you want
  ///             Note, some devices or urls jumps from 0 to 100 in one step
  ///[onDownloadCompleted] When the download is complete, this callback will be fired holding the file path
  ///[onDownloadError] When something unexpected happens, this callback will be fired
  static Future<File?> downloadFile({
    required final String url,
    final String? name,
    final String? subPath,
    final NotificationType notificationType = NotificationType.progressOnly,
    final DownloadDestinations downloadDestination =
        DownloadDestinations.publicDownloads,
    final DownloadService downloadService = DownloadService.downloadManager,
    final DownloadRequestMethodType methodType = DownloadRequestMethodType.get,
    final Map<String, String> headers = const {},
    final OnDownloadRequestIdReceived? onDownloadRequestIdReceived,
    final OnProgress? onProgress,
    final OnDownloadCompleted? onDownloadCompleted,
    final OnDownloadError? onDownloadError,
  }) async {
    return FileDownloader()
        ._downloadFile(
          url: url,
          name: name,
          subPath: subPath,
          notificationType: notificationType,
          downloadDestination: downloadDestination,
          downloadService: downloadService,
          methodType: methodType,
          headers: headers,
          onDownloadRequestIdReceived: onDownloadRequestIdReceived,
          onProgress: onProgress,
          onDownloadCompleted: onDownloadCompleted,
          onDownloadError: onDownloadError,
        )
        .catchError((error) => throw error);
  }

  /// simple download task,
  /// downloads the file in [url] to Downloads/ dir
  /// using [DownloadService.downloadManager] service
  /// [url] the URL to download
  /// returns [File] if the download succeed
  /// returns [null] if the download fail
  static Future<File?> simpleDownload(final String url) async {
    return FileDownloader()
        ._downloadFile(url: url)
        .catchError((error) => throw error);
  }

  ///Writes content into a file
  ///[content] the content will be written into the file, MUST BE Base64 String
  ///[fileName] the created file name
  ///[extension] the file mimeType
  ///[downloadDestination] the file destination dir/
  ///[onProgress] a progress callback to track file creation progress
  ///[onCompleted] a completion callback to track when created is completed
  ///[onError] a failure callback to track when created has failed
  ///returns the created [File] if succeed
  static Future<File?> writeFile({
    required final String content,
    required final String fileName,
    required final String extension,
    final String? subPath,
    final DownloadDestinations downloadDestination =
        DownloadDestinations.publicDownloads,
    final OnProgress? onProgress,
    final OnDownloadCompleted? onCompleted,
    final OnDownloadError? onError,
  }) async {
    return FileDownloader()._writeFile(
      content: content,
      fileName: fileName,
      extension: extension,
      subPath: subPath,
      downloadDestination: downloadDestination,
      onProgress: onProgress,
      onCompleted: onCompleted,
      onError: onError,
    );
  }

  ///[urls] a list of urls to files to be downloaded
  ///[downloadDestination] the desired download location, this can either be public download directory (Default)
  ///                       or the app's private files directory
  ///[isParallel] this indicates that the download process must be parallel or
  ///             download file by file to reduce device's resource consumption
  ///             if this is set to true (Default), this will not exceed [MaximumParallelDownloads] (25 by default)
  ///[onAllDownloaded] this callback will be triggered once all files downloaded are done
  ///                   note that some of the files might fail downloading
  ///                   and the files will be in the same order of the urls
  ///                   a filed to download file will be null at it's index
  static Future<List<File?>> downloadFiles({
    required final List<String> urls,
    final NotificationType notificationType = NotificationType.progressOnly,
    final DownloadDestinations downloadDestination =
        DownloadDestinations.publicDownloads,
    final bool isParallel = true,
    final VoidCallback? onAllDownloaded,
    final Map<String, String> headers = const {},
  }) async {
    if (isParallel) {
      final result = <int, File?>{};
      final tasks = List<bool>.generate(urls.length, (_) => false);
      final completer = Completer();
      for (int i = 0; i < urls.length; i++) {
        result[i] = null;
        downloadFile(
            url: urls[i],
            notificationType: notificationType,
            downloadDestination: downloadDestination,
            headers: headers,
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
          await downloadFile(
            url: url,
            notificationType: notificationType,
            headers: headers,
            downloadDestination: downloadDestination,
          ).catchError((error) => null),
      ];
      onAllDownloaded?.call();
      return result;
    }
  }

  /// A batch-download request method to pass a different headers for each file
  ///
  /// this method is used when you have multiple files to download
  /// and [DownloadFileRequest.headers] are different for each download request
  ///
  /// takes:
  /// - [requests] a List of [DownloadFileRequest] to download
  /// - [notificationType] to manage download progress notifications; default is [NotificationType.progressOnly]
  /// - [downloadDestination] to determine where to download these files, public downloads directory or app directory (temp files)
  /// - [isParallel] to manage requests flow, whether parallel or not; default is true
  /// - [onAllDownloaded] a callback when batch download is done
  ///
  /// returns:
  /// - an array of nullable [File] in the same order of the requests
  static Future<List<File?>> downloadFilesWithCustomHeaders({
    required final List<DownloadFileRequest> requests,
    final NotificationType notificationType = NotificationType.progressOnly,
    final DownloadDestinations downloadDestination =
        DownloadDestinations.publicDownloads,
    final bool isParallel = true,
    final VoidCallback? onAllDownloaded,
  }) async {
    if (isParallel) {
      final result = <int, File?>{};
      final tasks = List<bool>.generate(requests.length, (_) => false);
      final completer = Completer();
      for (int i = 0; i < requests.length; i++) {
        result[i] = null;
        downloadFile(
            url: requests[i].url,
            notificationType: notificationType,
            downloadDestination: downloadDestination,
            headers: requests[i].headers,
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
        for (final request in requests)
          await downloadFile(
            url: request.url,
            notificationType: notificationType,
            headers: request.headers,
            downloadDestination: downloadDestination,
          ).catchError((error) => null),
      ];
      onAllDownloaded?.call();
      return result;
    }
  }

  /// to cancel a download request by it's id
  ///
  /// [downloadId] the download task id to be canceled
  static Future<bool> cancelDownload(final int downloadId) async {
    try {
      final result = await _platform.invokeMethod('cancelDownload', {
        'id': '$downloadId',
      });
      return result as bool;
    } catch (e) {
      debugPrint('downloadFile error: $e');
    }
    return false;
  }

  Future<File?> _writeFile({
    required final String content,
    required final String fileName,
    required final String extension,
    final String? subPath,
    final DownloadDestinations downloadDestination =
        DownloadDestinations.publicDownloads,
    final OnProgress? onProgress,
    final OnDownloadCompleted? onCompleted,
    final OnDownloadError? onError,
  }) async {
    try {
      final task = _PluginTask(
        content: content.trim(),
        name: fileName.trim().isEmpty ? 'file-${_taskID + 1}' : fileName.trim(),
        subPath: subPath,
        extension: extension,
        downloadDestination: downloadDestination,
        callbacks: DownloadCallbacks(
          onProgress: onProgress,
          onDownloadCompleted: onCompleted,
          onDownloadError: onError,
        ),
      );
      task.key = (++_taskID);
      _queueTask(task);
      _downloadTasks[task.key] = task;

      print('===== WRITE FILE =====');
      for (final entry in task.toMap().entries) {
        print('${entry.key}: ${entry.value}');
      }
      print('===== WRITE FILE =====');

      final result = await _platform.invokeMethod(
        'writeFile',
        task.toMap(),
      );
      if (result is String && result.isNotEmpty) {
        return File(result);
      }
    } catch (e) {
      debugPrint('downloadFile error: $e');
    }
    return Future.value(null);
  }

  Future<File?> _downloadFile({
    required final String url,
    final String? name,
    final String? subPath,
    final NotificationType notificationType = NotificationType.all,
    final DownloadDestinations downloadDestination =
        DownloadDestinations.publicDownloads,
    final DownloadService downloadService = DownloadService.downloadManager,
    final DownloadRequestMethodType methodType = DownloadRequestMethodType.get,
    final Map<String, String> headers = const {},
    final OnDownloadRequestIdReceived? onDownloadRequestIdReceived,
    final OnProgress? onProgress,
    final OnDownloadCompleted? onDownloadCompleted,
    final OnDownloadError? onDownloadError,
  }) async {
    if (!Platform.isAndroid) {
      debugPrint(
          '[flutter_file_downloader] this plugin currently supports only android platform');
      return Future.value(null);
    }
    if (!(Uri.tryParse(url)?.hasAbsolutePath ?? false)) {
      final error =
          'URL is not valid, "$url" is not a valid url, please double check it then try again';
      if (onDownloadError != null) {
        onDownloadError.call(error);
        return null;
      } else {
        throw Exception(error);
      }
    }
    final task = _PluginTask(
      url: url.trim(),
      name: name?.trim(),
      subPath: subPath,
      notificationType: notificationType,
      downloadDestination: downloadDestination,
      downloadService: downloadService,
      methodType: methodType,
      headers: headers,
      callbacks: DownloadCallbacks(
        onDownloadRequestIdReceived: onDownloadRequestIdReceived,
        onProgress: onProgress,
        onDownloadCompleted: onDownloadCompleted,
        onDownloadError: onDownloadError,
      ),
    );
    task.key = (++_taskID);
    _queueTask(task);
    _downloadTasks[task.key] = task;
    try {
      final result = await _platform.invokeMethod(
        'downloadFile',
        task.toMap(),
      );
      if (result is String && result.isNotEmpty) {
        return File(result);
      }
    } catch (e) {
      debugPrint('downloadFile error: $e');
    }
    return Future.value(null);
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    final id = call.arguments['id'].toString();
    final int key = int.parse(call.arguments['key'].toString());

    switch (call.method) {
      case 'onIDReceived':
        _log('File ${call.arguments['url']} got the id $id');
        _downloadTasks[key]?.id = id;
        _downloadTasks[key]
            ?.callbacks
            .onDownloadRequestIdReceived
            ?.call(int.parse(id));
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
        _downloadTasks[key]?.notifyCompleted(true);
        _downloadTasks[key]
            ?.callbacks
            .onDownloadCompleted
            ?.call(call.arguments['path']);
        _downloadTasks.remove(key);
        break;
      case 'onDownloadError':
        _log(
            'Task ${call.arguments['key']} failed to download: ${call.arguments['error']}');
        _downloadTasks[key]?.notifyCompleted(false);
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

  void _queueTask(final _PluginTask task) {
    if (_processingDownloads.length < _maximumParallelDownloads) {
      _log('Start downloading task no ${task.key}');
      _processingDownloads[_taskID] = task;
      task.waitDownload().whenComplete(() {
        _log(
            'Download task ${task.key} is done, checking for waiting tasks...');
        _processingDownloads.remove(task.key);
        _startWaitingTask();
      });
    } else {
      _log(
          'Task ${task.key} is queued because maximum parallel download is reached');
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
