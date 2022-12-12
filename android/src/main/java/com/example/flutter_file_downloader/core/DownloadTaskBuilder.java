package com.example.flutter_file_downloader.core;

import android.app.Activity;

public class DownloadTaskBuilder {
//    DownloadTaskBuilder instance;
    String url, name;
    DownloadCallbacks callbacks;
    boolean deleteOldVersion = false;
    final Activity activity;
    private DownloadTask task;

    public DownloadTaskBuilder(final Activity activity) {
        this.activity = activity;
//        instance = this;
    }

    public DownloadTaskBuilder setUrl(final String url) {
        this.url = url;
        return this;
    }

    public DownloadTaskBuilder setName(final String name) {
        this.name = name;
        return this;
    }

    public DownloadTaskBuilder setCallbacks(final DownloadCallbacks callbacks) {
        this.callbacks = callbacks;
        return this;
    }

    public DownloadTaskBuilder setDeleteOldVersion(final boolean delete) {
        deleteOldVersion = delete;
        return this;
    }

    public DownloadTask build() {
        if (task == null)
            task = new DownloadTask(
                    activity,
                    url,
                    name,
                    deleteOldVersion,
                    callbacks);
        try {
            return getDownloadTask();
        } catch (Exception e) {
            return task;
        }
    }

    public DownloadTask getDownloadTask() throws Exception {
        if (task == null)
            throw new Exception("build method is not called, you should call \"downloadTaskBuilder.build()\" first");
        return task;
    }
}
