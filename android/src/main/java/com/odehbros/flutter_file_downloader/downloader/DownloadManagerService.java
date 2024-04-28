package com.odehbros.flutter_file_downloader.downloader;

import android.app.Activity;
import android.app.DownloadManager;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.odehbros.flutter_file_downloader.PluginLogger;
import com.odehbros.flutter_file_downloader.StoreHelper;
import com.odehbros.flutter_file_downloader.core.DownloadCallbacks;
import com.odehbros.flutter_file_downloader.core.DownloadNotificationType;
import com.odehbros.flutter_file_downloader.downloadDestination.AppData;
import com.odehbros.flutter_file_downloader.downloadDestination.DownloadDestination;
import com.odehbros.flutter_file_downloader.downloadDestination.PublicDownloads;
import com.odehbros.flutter_file_downloader.fileStore.FileUtils;

import java.util.Map;

public class DownloadManagerService extends DownloadService {

    private final DownloadManager.Request downloadManager;
    private boolean isDownloading = false;

    public DownloadManagerService(Activity activity, String url, String name, DownloadNotificationType notifications, DownloadDestination downloadDestination, DownloadCallbacks callbacks, Map<String, String> requestHeaders, StoreHelper helper) {
        super(activity, url, name, notifications, downloadDestination, callbacks, requestHeaders, helper);

        downloadManager = new DownloadManager.Request(Uri.parse(url));

        setDownloadPath();
    }

    @Override
    protected void download() {
        isDownloading = true;
        //declare download manager instance with above configuration
        final DownloadManager manager = (DownloadManager) activity.getSystemService(Context.DOWNLOAD_SERVICE);
        try {
            //start download
            final long downloadedID = manager.enqueue(downloadManager);
            if (callbacks != null) {
                callbacks.onIDReceived(downloadedID);
                callbacks.onProgress(downloadedID);
                //track download
                trackDownload(manager, downloadedID);
            }
        } catch (Exception e) {
            String message;
            if (e.getMessage().startsWith("Unsupported path") || e.getMessage().startsWith("java.io.IOException: Invalid file path")) {
                message = "Invalid file name " + getFileName() + " try changing the download file name";
            } else if (e instanceof SecurityException) {
                Log.e("MISSING PERMISSION", "If you want to download a file without notifications, you must provide the permission\n<uses-permission android:name=\"android.permission.DOWNLOAD_WITHOUT_NOTIFICATION\" />");
                message = "Missing permission, see the log for more info";
            } else {
                message = e.getMessage();
            }

            PluginLogger.logThrowable(e);

            new Handler(Looper.getMainLooper()).post(() -> {
                callbacks.onDownloadError(message);
            });
//            helper.result.error("Download file error", message + "", null);
        }
    }

    @Override
    public boolean cancelDownload(long id) {
        DownloadManager downloadManager = (DownloadManager) activity.getSystemService(Context.DOWNLOAD_SERVICE);
        final int removedCount = downloadManager.remove(id);
        return removedCount > 0;
    }

    @Override
    protected void appendHeaders() {
        for (final Map.Entry<String, String> entry : headers.entrySet()) {
            downloadManager.addRequestHeader(entry.getKey(), entry.getValue());
        }
    }

    @Override
    protected void handleNotificationsStatus() {
        switch (notifications) {
            case ALL:
                downloadManager.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
                break;
            case PROGRESS_ONLY:
                downloadManager.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE);
                break;
            case COMPLETION_ONLY:
                downloadManager.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_ONLY_COMPLETION);
                break;
            case OFF:
                downloadManager.setNotificationVisibility(DownloadManager.Request.VISIBILITY_HIDDEN);
                break;
        }
    }

    private void setDownloadPath() {
        final String dir = downloadDestination.getDirectoryPath().getPath();
        final String subPath = FileUtils.fixSubPath(downloadDestination.subPath);
        final String fileName = String.format("%s%s", subPath, getFileName());
        final String dirPath = String.format("%s/%s", dir, subPath);
        final String fullPath = String.format("%s/%s", dir, fileName);
        final boolean dirsCreated = FileUtils.createDir(dirPath);
        PluginLogger.log("Dir path: " + dirPath + ", has created dirs? " + dirsCreated);
        if (downloadDestination instanceof AppData) {
            downloadManager.setDestinationInExternalFilesDir(
                    activity,
                    dir,
                    fileName);
        } else if (downloadDestination instanceof PublicDownloads) {
            downloadManager.setDestinationInExternalPublicDir(
                    Environment.DIRECTORY_DOWNLOADS,
                    fileName);
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
                System.out.println("Download ID: " + downloadID + ", bytesTotal: " + bytesTotal + ", bytesDownloaded: " + bytesDownloaded);
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
}
