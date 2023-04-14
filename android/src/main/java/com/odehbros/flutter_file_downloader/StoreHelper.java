package com.odehbros.flutter_file_downloader;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class StoreHelper {

    public String id;
    public MethodCall call;
    public MethodChannel.Result result;

    public StoreHelper(final MethodCall call, final MethodChannel.Result result) {
        this.call = call;
        this.result = result;
    }
}