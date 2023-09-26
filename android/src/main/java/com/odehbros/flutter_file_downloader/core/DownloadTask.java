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
        final DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));

        final String downloadFileName = getDownloadedFileName();
        final String fixedDownloadedFileName = fixDownloadFileName(downloadFileName);

        if (TextUtils.isEmpty(fixedDownloadedFileName)) {
            final String message = "Invalid file name "+downloadFileName+" -> "+fixedDownloadedFileName+" try changing the download file name";
            new Handler(Looper.getMainLooper()).post(() -> {
                callbacks.onDownloadError(message);
            });
            helper.result.error("Download file error", message + "", null);
            return;
        }


        if ("appFiles".equals(downloadDestination)) {
            request.setDestinationInExternalFilesDir(activity, PathUtils.getFilesDir(activity), fixedDownloadedFileName);
        } else if ("publicDownloads".equals(downloadDestination)) {
            request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fixedDownloadedFileName);
        }
        if ("disabled".equals(notifications)) {
            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_HIDDEN);
        } else if ("all".equals(notifications)) {
            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
        } else if ("progressOnly".equals(notifications)) {
            //DO NOTHING (DEFAULT CASE)
        }
        for (final Map.Entry<String, String> entry : requestHeaders.entrySet()) {
            request.addRequestHeader(entry.getKey(), entry.getValue());
        }
        final DownloadManager manager = (DownloadManager) activity.getSystemService(activity.DOWNLOAD_SERVICE);
        try {
            final long downloadedID = manager.enqueue(request);
            if (callbacks != null) {
                callbacks.onIDReceived(downloadedID);
                trackDownload(manager, downloadedID);
            }
        } catch (Exception e) {
            String message;
            if (e.getMessage().startsWith("Unsupported path") || e.getMessage().startsWith("java.io.IOException: Invalid file path")) {
                message = "Invalid file name "+getDownloadedFileName()+" try changing the download file name";
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
                int bytesDownloaded;
                int bytesTotal;
                int status;
                try {
                    bytesDownloaded = cursor.getInt(downloadedCursorColumnIndex);
                    bytesTotal = cursor.getInt(totalCursorColumnIndex);
                    status = cursor.getInt(statusColumnIndex);
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
                        uiThreadHandler.post(() -> {
                            callbacks.onProgress(progress);
                            callbacks.onProgress(getDownloadedFileName(), progress);
                        });
                    }
                    lastProgress = progress;
                }
                cursor.close();
            }
        }).start();
    }

    private String getName() {
        if (!TextUtils.isEmpty(name)) return name;
        final String[] segments = url.split("/");
        return segments[segments.length - 1];
    }

    private String getExtension() {
//        String toCheck = name;
//        if (!TextUtils.isEmpty(toCheck)) {
//            if (!toCheck.contains(".")) {
//                final String[] segments = url.split("/");
//                toCheck = segments[segments.length - 1];
//            }
//        } else {
//            toCheck = getName();
//        }

        final String[] segments = url.split("/");
        String toCheck = segments[segments.length - 1];

        return toCheck.substring(toCheck.lastIndexOf("."));
    }

    private String getDownloadedFileName() {
        if (TextUtils.isEmpty(name)) return getName();
        String name = getName();
        final String extension = getExtension();
        if (name.contains(".")) {
            name = name.substring(0, name.lastIndexOf("."));
//            name = fixDownloadFileName(name);
        }
        return String.format("%s.%s", name, extension.replace(".", ""));
    }

    private String fixDownloadFileName(final String name) {
        String extension = "";
        if (name.contains(getExtension())) {
            extension = name.substring(name.lastIndexOf("."));
        }
//        Log.i("FIXING FNAME", name + " -> "+ extension + " | " + getExtension());
        return name
                .replace(extension, "")
                .replace("#", "")
                .replace("%", "")
                .replace("*", "")
                .replace(".", "")
                .replace("\\", "")
                .replace("|", "")
                .replace("\"", "")
                .replace(":", "")
                .replace(":", "")
                .replace("/", "")
                .replace("<", "")
                .replace(">", "")
                .replace("?", "")
                .replace("&", "")
                + getExtension();
    }
}
