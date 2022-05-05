package com.example.flutter_file_downloader.core;

import android.app.Activity;
import android.app.DownloadManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Environment;
import android.text.TextUtils;
import android.util.Log;
import android.os.Handler;
import android.os.Looper;

public class DownloadTask {
    final Activity activity;
    final String url, name;
    final DownloadCallbacks callbacks;
    private boolean isDownloading = false;

    public DownloadTask(Activity activity, String url, String name, DownloadCallbacks callbacks) {
        this.callbacks = callbacks;
        this.activity = activity;
        this.url = url;
        this.name = name;
    }

    public DownloadTask(Activity activity, String url, String name) {
        this.activity = activity;
        this.url = url;
        this.name = name;
        callbacks = null;
    }

    public void startDownloading() {
        isDownloading = true;
        final DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));

        request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, getDownloadedFileName());

        String path = Environment
                .getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                .getAbsolutePath() + "/" + getDownloadedFileName();

        System.out.println("FILE PATH: "+path);
        final DownloadManager manager = (DownloadManager) activity.getSystemService(activity.DOWNLOAD_SERVICE);
        final long downloadedID = manager.enqueue(request);
        if (callbacks != null) {
            callbacks.onIDReceived(downloadedID);
            trackDownload(manager, downloadedID);
        }
    }

    private void trackDownload(final DownloadManager manager, final long downloadID) {

        Handler uiThreadHandler = new Handler(Looper.getMainLooper());
        new Thread(new Runnable() {
            @Override
            public void run() {
                double lastProgress = -1;

                while (isDownloading) {

                    DownloadManager.Query q = new DownloadManager.Query();
                    q.setFilterById(downloadID);

                    Cursor cursor = manager.query(q);
                    cursor.moveToFirst();
                    int bytes_downloaded = cursor.getInt(cursor
                            .getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
                    int bytes_total = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));

                    if (cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_STATUS)) == DownloadManager.STATUS_SUCCESSFUL) {
                        isDownloading = false;
                    }

                    final double dl_progress = (int) ((bytes_downloaded * 100l) / bytes_total);
//                    System.out.println("DOWNLOADED: "+bytes_downloaded+", TOTAL: "+bytes_total);
                    if (lastProgress != dl_progress) {
                        uiThreadHandler.post(() -> {
                            callbacks.onProgress(dl_progress);
                            callbacks.onProgress(getDownloadedFileName(), dl_progress);
                        });
                        lastProgress = dl_progress;
                    }
                    cursor.close();
                }

            }
        }).start();
    }

    private String getName() {
        if (!TextUtils.isEmpty(name)) return name;
        final String[] segments = url.split("/");
        return segments[segments.length - 1];
    }

    private String getExtension() {
        String toCheck = name;
        if (!TextUtils.isEmpty(toCheck)) {
            if (!toCheck.contains(".")) {
                final String[] segments = url.split("/");
                toCheck = segments[segments.length - 1];
            }
        } else
            toCheck = getName();

        return toCheck.substring(toCheck.lastIndexOf("."));
    }

    private String getDownloadedFileName() {
        if (TextUtils.isEmpty(name)) return getName();
        String name = getName();
        final String extension = getExtension();
        if (name.contains(".")) {
            name = name.substring(0, name.lastIndexOf("."));
        }
        return String.format("%s.%s", name, extension.replace(".", ""));
    }
}
