package com.odehbros.flutter_file_downloader;

import android.util.Log;

public class PluginLogger {

    static private boolean shouldLog = true;

    private static PluginLogger instance = new PluginLogger();

    private PluginLogger() {
    }

    static public PluginLogger getInstance() {
        return instance;
    }

    static public void log(final String data) {
        if (!shouldLog) return;
        Log.i("flutter_file_downloader", data);
    }

    static public void logThrowable(Throwable throwable) {
        throwable.printStackTrace();
    }
}
