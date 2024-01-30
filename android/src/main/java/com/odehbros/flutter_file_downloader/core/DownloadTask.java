package com.odehbros.flutter_file_downloader.core;

import android.app.Activity;
import android.app.DownloadManager;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;

import java.util.List;
import java.util.Map;

import io.flutter.util.PathUtils;

import com.odehbros.flutter_file_downloader.StoreHelper;

public class DownloadTask {
    final Activity activity;
    final String url, name, downloadDestination;
    final DownloadCallbacks callbacks;
    final Map<String, String> requestHeaders;
    final String notifications;
    private boolean isDownloading = false;
    final StoreHelper helper;

    public DownloadTask(Activity activity, String url, String name, String notifications, String downloadDestination, DownloadCallbacks callbacks, Map<String, String> requestHeaders, StoreHelper helper) {
        this.activity = activity;
        this.url = url;
        this.name = name;
        this.notifications = notifications;
        this.downloadDestination = downloadDestination;
        this.callbacks = callbacks;
        this.requestHeaders = requestHeaders;
        this.helper = helper;
    }

    public void startDownloading(final Context context) {
        isDownloading = true;
        final Uri uri = Uri.parse(url);
        final List<String> path = uri.getPathSegments();
        final String originalName = path.get(path.size() - 1);
        final DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));

        final String downloadName = getDownloadFileName(name, originalName);

        if (TextUtils.isEmpty(downloadName)) {
            final String message = "Invalid file name " + downloadName + " try changing the download file name";
            new Handler(Looper.getMainLooper()).post(() -> {
                callbacks.onDownloadError(message);
            });
            helper.result.error("Download file error", message + "", null);
            return;
        }

        //set download destination
        if ("appFiles".equals(downloadDestination)) {
            request.setDestinationInExternalFilesDir(activity, PathUtils.getFilesDir(activity), downloadName);
        } else if ("publicDownloads".equals(downloadDestination)) {
            request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, downloadName);
        }

        //set notification status
        if ("disabled".equals(notifications)) {
            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_HIDDEN);
        } else if ("all".equals(notifications)) {
            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
        } else if ("progressOnly".equals(notifications)) {
            //DO NOTHING (DEFAULT CASE)
        }

        //append headers
        for (final Map.Entry<String, String> entry : requestHeaders.entrySet()) {
            request.addRequestHeader(entry.getKey(), entry.getValue());
        }

        //declare download manager instance with above configuration
        final DownloadManager manager = (DownloadManager) activity.getSystemService(activity.DOWNLOAD_SERVICE);
        try {
            //start download
            final long downloadedID = manager.enqueue(request);
            if (callbacks != null) {
                callbacks.onIDReceived(downloadedID);
                //track download
                trackDownload(manager, downloadedID);
            }
        } catch (Exception e) {
            String message;
            if (e.getMessage().startsWith("Unsupported path") || e.getMessage().startsWith("java.io.IOException: Invalid file path")) {
                message = "Invalid file name " + downloadName + " try changing the download file name";
            } else if (e instanceof SecurityException) {
                Log.e("MISSING PERMISSION", "If you want to download a file without notifications, you must provide the permission\n<uses-permission android:name=\"android.permission.DOWNLOAD_WITHOUT_NOTIFICATION\" />");
                message = "Missing permission, see the log for more info";
            } else {
                message = e.getMessage();
            }

            new Handler(Looper.getMainLooper()).post(() -> {
                callbacks.onDownloadError(message);
            });
            helper.result.error("Download file error", message + "", null);
        }
    }

    private void trackDownload(final DownloadManager manager, final long downloadID) {
        Handler uiThreadHandler = new Handler(Looper.getMainLooper());
        new Thread(() -> {
            double lastProgress = -1;

            while (isDownloading) {
                DownloadManager.Query q = new DownloadManager.Query();
                q.setFilterById(downloadID);

                Cursor cursor = manager.query(q);
                cursor.moveToFirst();
                final int downloadedCursorColumnIndex = cursor.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR);
                final int totalCursorColumnIndex = cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES);
                final int statusColumnIndex = cursor.getColumnIndex(DownloadManager.COLUMN_STATUS);
                final int downloadNameColumnIndex = cursor.getColumnIndex(DownloadManager.COLUMN_TITLE);
                int bytesDownloaded;
                int bytesTotal;
                int status;
                String downloadName;
                try {
                    bytesDownloaded = cursor.getInt(downloadedCursorColumnIndex);
                    bytesTotal = cursor.getInt(totalCursorColumnIndex);
                    status = cursor.getInt(statusColumnIndex);
                    downloadName = cursor.getString(downloadNameColumnIndex);
                } catch (Exception e) {
                    isDownloading = false;
                    if (callbacks != null) {
                        uiThreadHandler.post(() -> {
                            callbacks.onDownloadError("Download canceled or failed due to network issues");
                        });
                    }
                    break;
                }
                if (status == DownloadManager.STATUS_SUCCESSFUL) {
                    isDownloading = false;
                }

                if (bytesTotal == 0) {
                    isDownloading = false;
                    if (callbacks != null) {
                        uiThreadHandler.post(() -> {
                            callbacks.onDownloadError("File size is Zero!");
                        });
                    }
                    break;
                }

                final double progress = (int) ((bytesDownloaded * 100L) / bytesTotal);
                if (lastProgress != progress) {
                    if (callbacks != null) {
                        if (downloadName != null && !downloadName.isEmpty()) {
                            uiThreadHandler.post(() -> {
                                //removed to avoid redundant calls to onProgress
//                            callbacks.onProgress(progress);
                                callbacks.onProgress(downloadName, progress);
                            });
                        }
                    }
                    lastProgress = progress;
                }
                cursor.close();
            }
        }).start();
    }

    private String fixDownloadFileName(final String name) {
        return name
                .replace("#", "")
                .replace("%", "")
                .replace("*", "")
                .replace(".", "")
                .replace("\\", "")
                .replace("|", "")
                .replace("\"", "")
                .replace(":", "")
                .replace("/", "")
                .replace("<", "")
                .replace(">", "")
                .replace("?", "")
                .replace("&", "");
    }

    private String getDownloadFileName(final String sentName, final String originalName) {
        String name = null;
        String extension = null;

        if (!TextUtils.isEmpty(sentName)) {
            name = extractFileName(sentName);
//            extension = getExtensionFrom(sentName);
        }

        if (TextUtils.isEmpty(name)) {
            name = extractFileName(originalName);
        }

        // Get file extension from the URL e.g. https://myurl.com/file.pdf
        extension = getExtensionFrom(originalName);
//        final String realExtension = getExtensionFrom(originalName);
//        if (TextUtils.isEmpty(extension) || !realExtension.equals(extension)) {
//            extension = realExtension;
//        }

//        return name;

        // If the URL does not contain file extension
        // e.g. https://myurl.com/myfile
        // then we try to extract it from the sent custom name if passed
        if (extension == null) {
            extension = getExtensionFrom(sentName);
        }

        // If no extension is provided neither in URL or custom file name,
        // we download the file without extension (might lead to improper file opening)
        if (extension == null) {
            return name;
        }

        // otherwise, we append the extension to file name
        return String.format("%s.%s", name, extension);
    }

    private String getExtensionFrom(final String name) {
        if (name == null) return null;
        final String[] arr = name.split("\\.");
        if (arr.length == 1) return null;
        return arr[arr.length - 1];
    }

    private String extractFileName(final String name) {
        final String[] terms = name.split("\\.");
        return fixDownloadFileName(terms[0]);
    }
}
