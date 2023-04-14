package com.odehbros.flutter_file_downloader.core;

import android.app.Activity;

public class DownloadTaskBuilder {
    DownloadTaskBuilder instance;
    String url, name;
    DownloadCallbacks callbacks;
    final Activity activity;
    private DownloadTask task;

    public DownloadTaskBuilder(final Activity activity) {
        this.activity = activity;
        instance = this;
    }

    public DownloadTaskBuilder setUrl(final String url) {
        instance.url = url;
        return instance;
    }

    public DownloadTaskBuilder setName(final String name) {
        instance.name = name;
        return instance;
    }

    public DownloadTaskBuilder setCallbacks(final DownloadCallbacks callbacks) {
        instance.callbacks = callbacks;
        return instance;
    }

    public DownloadTask build() {
        if (task == null)
            task = new DownloadTask(instance.activity, instance.url, instance.name, callbacks);
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
