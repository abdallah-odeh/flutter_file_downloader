package com.odehbros.flutter_file_downloader.core;

import android.app.Activity;

import java.util.Map;
import com.odehbros.flutter_file_downloader.StoreHelper;

public class DownloadTaskBuilder {
    String url, name, downloadDestination;
    String notifications = "progressOnly";
    DownloadCallbacks callbacks;
    final Activity activity;
    private DownloadTask task;
    private Map<String, String> requestHeaders;
    private StoreHelper helper;

    public DownloadTaskBuilder(final Activity activity) {
        this.activity = activity;
    }

    public DownloadTaskBuilder setUrl(final String url) {
        this.url = url;
        return this;
    }

    public DownloadTaskBuilder setName(final String name) {
        this.name = name;
        return this;
    }

    public DownloadTaskBuilder setShowNotifications(String notifications) {
        if (notifications != null && !notifications.isEmpty())
            this.notifications = notifications;
        return this;
    }

    public DownloadTaskBuilder setDownloadDestination(final String downloadDestination) {
        this.downloadDestination = downloadDestination;
        return this;
    }

    public DownloadTaskBuilder setCallbacks(final DownloadCallbacks callbacks) {
        this.callbacks = callbacks;
        return this;
    }

    public DownloadTaskBuilder setRequestHeaders(final Map<String, String> requestHeaders) {
        this.requestHeaders = requestHeaders;
        return this;
    }

    public DownloadTaskBuilder setStoreHelper(final StoreHelper helper) {
        this.helper = helper;
        return  this;
    }

    public DownloadTask build() {
        if (task == null)
            task = new DownloadTask(activity, url, name, notifications, downloadDestination, callbacks, requestHeaders, helper);
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
