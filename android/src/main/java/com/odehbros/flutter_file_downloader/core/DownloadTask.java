package com.odehbros.flutter_file_downloader.core;

import android.app.Activity;
import android.text.TextUtils;

import com.odehbros.flutter_file_downloader.MethodCallHandlerImpl;
import com.odehbros.flutter_file_downloader.PluginLogger;
import com.odehbros.flutter_file_downloader.StoreHelper;
import com.odehbros.flutter_file_downloader.downloadDestination.AppData;
import com.odehbros.flutter_file_downloader.downloadDestination.DownloadDestination;
import com.odehbros.flutter_file_downloader.downloadDestination.PublicDownloads;
import com.odehbros.flutter_file_downloader.downloader.DownloadManagerService;
import com.odehbros.flutter_file_downloader.downloader.DownloadService;
import com.odehbros.flutter_file_downloader.downloader.HttpDownload;
import com.odehbros.flutter_file_downloader.notificationService.NotificationTexts;

import java.util.Map;

enum DownloadTaskService {HTTP_CONNECTION, DOWNLOAD_MANAGER}

public class DownloadTask {
    final Activity activity;
    String url;
    String name;
    String subPath;
    DownloadNotificationType notifications;
    DownloadDestination downloadDestination;
    DownloadRequestMethodType methodType;
    DownloadCallbacks callbacks;
    Map<String, String> requestHeaders;
    StoreHelper helper;
    NotificationTexts notificationTexts;
    DownloadTaskService service;
    MethodCallHandlerImpl methodCallHandler;

    public DownloadTask(Activity activity) {
        this.activity = activity;
    }

    public DownloadTask setUrl(String url) {
        this.url = url;
        return this;
    }

    public DownloadTask setName(String name) {
        this.name = name;
        return this;
    }

    public DownloadTask setSubPath(String subPath) {
        this.subPath = subPath;
        return this;
    }

    public DownloadTask setNotifications(String notifications) {
        switch (notifications.toLowerCase()) {
            case "all":
                this.notifications = DownloadNotificationType.ALL;
                break;
            case "progress_only":
            case "progressonly":
                this.notifications = DownloadNotificationType.PROGRESS_ONLY;
                break;
            case "completion_only":
            case "completiononly":
                this.notifications = DownloadNotificationType.COMPLETION_ONLY;
                break;
            case "off":
            case "disabled":
                this.notifications = DownloadNotificationType.OFF;
                break;
            default:
                PluginLogger.log("No notification type with name " + notifications);
        }

        return this;
    }

    public DownloadTask setDownloadDestination(String downloadDestination) {
        switch (downloadDestination.toLowerCase()) {
            case "publicdownloads":
                this.downloadDestination = new PublicDownloads(subPath);
                break;
            case "appfiles":
                this.downloadDestination = new AppData(activity, subPath);
                break;
            default:
                PluginLogger.log("No destination with name " + downloadDestination);
        }
        return this;
    }

    public DownloadTask setMethodType(String methodType) {
        switch (methodType.toLowerCase()) {
            case "get":
                this.methodType = DownloadRequestMethodType.GET;
                break;
            case "post":
                this.methodType = DownloadRequestMethodType.POST;
                service = DownloadTaskService.HTTP_CONNECTION;
                break;
            default:
                PluginLogger.log("No method type with name " + methodType);
        }
        return this;
    }

    public DownloadTask setCallbacks(DownloadCallbacks callbacks) {
        this.callbacks = callbacks;
        return this;
    }

    public DownloadTask setRequestHeaders(Map<String, String> requestHeaders) {
        this.requestHeaders = requestHeaders;
        return this;
    }

    public DownloadTask setHelper(StoreHelper helper) {
        this.helper = helper;
        return this;
    }

    public DownloadTask setMethodCallHandler(MethodCallHandlerImpl methodCallHandler) {
        this.methodCallHandler = methodCallHandler;
        return this;
    }

    public DownloadTask setNotificationTexts(NotificationTexts notificationTexts) {
        this.notificationTexts = notificationTexts;
        return this;
    }

    public DownloadTask setDownloadService(String service) {
        switch (service.toLowerCase()) {
            case "downloadmanager":
                if (methodType != DownloadRequestMethodType.GET) {
                    setService(DownloadTaskService.HTTP_CONNECTION);
                } else {
                    // since DownloadManager does only support GET request,
                    // we force setting it to DownloadManager
                    setService(DownloadTaskService.DOWNLOAD_MANAGER);
                }
                break;
            case "httpconnection":
                setService(DownloadTaskService.HTTP_CONNECTION);
                break;
        }
        return this;
    }

    private void setService(final DownloadTaskService service) {
        this.service = service;
    }

    public DownloadService build() {
        if (!isValidRequest()) return null;
        switch (service) {
            case HTTP_CONNECTION:
                return new HttpDownload(
                        activity,
                        url,
                        name,
                        notifications,
                        downloadDestination,
                        callbacks,
                        requestHeaders,
                        helper,
                        methodCallHandler,
                        notificationTexts);
            case DOWNLOAD_MANAGER:
                return new DownloadManagerService(
                        activity,
                        url,
                        name,
                        notifications,
                        downloadDestination,
                        callbacks,
                        requestHeaders,
                        helper);
        }
        return null;
    }

    private boolean isValidRequest() {
        if (activity == null) return false;
        if (TextUtils.isEmpty(url)) return false;
        if (downloadDestination == null) return false;
        return true;
    }
}
