package com.odehbros.flutter_file_downloader.core;

public class DownloadCallbacks {
    public long id;

    public void onIDReceived(final long id) {
        this.id = id;
    }

    public void onProgress(final double progress) {
    }

    public void onProgress(final String name, final double progress) {
    }

    public void onDownloadCompleted(final String path) {
    }

    public void onDownloadError(final String errorMessage) {
    }
}
