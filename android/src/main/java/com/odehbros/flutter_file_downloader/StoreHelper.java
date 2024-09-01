package com.odehbros.flutter_file_downloader;

import com.odehbros.flutter_file_downloader.downloader.DownloadService;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class StoreHelper {

    public String id;
    private DownloadService service;
    public MethodCall call;
    public MethodChannel.Result result;

    public StoreHelper(final MethodCall call, final MethodChannel.Result result) {
        this.call = call;
        this.result = result;
    }

    public void setDownloadService(final DownloadService service) {
        this.service = service;
    }

    public DownloadService getDownloadService() {
        return service;
    }
}