package com.example.flutter_file_downloader;

import android.app.Activity;
import android.content.Context;
import android.util.Log;
//import android.Manifest;
import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.example.flutter_file_downloader.errors.ErrorCodes;
import com.example.flutter_file_downloader.errors.PermissionUndefinedException;
import com.example.flutter_file_downloader.permission.StoragePermission;
import com.example.flutter_file_downloader.permission.PermissionManager;
import com.example.flutter_file_downloader.permission.PermissionResultCallback;
import com.example.flutter_file_downloader.core.DownloadCallbacks;
import com.example.flutter_file_downloader.core.DownloadTaskBuilder;
import com.example.flutter_file_downloader.core.DownloadTask;
import com.example.flutter_file_downloader.StoreHelper;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import java.util.Map;
import java.util.HashMap;

public class MethodCallHandlerImpl implements MethodChannel.MethodCallHandler {

    private static final String CHANNEL = "com.abdallah.libs/file_downloader";
    private static final String TAG = "MethodCallHandlerImpl";
    private final PermissionManager permissionManager;

    @Nullable
    private Context context;
    @Nullable
    private Activity activity;

    private String lastURL, lastName;
//    private MethodCall lastCall;
//    public MethodChannel.Result lastResult;
    private final Map<Long, DownloadCallbacks> tasks = new HashMap<>();
    private final Map<String, StoreHelper> stored = new HashMap<>();

    MethodCallHandlerImpl(
            PermissionManager permissionManager) {
        System.out.println("MethodCallHandlerImpl INSTANCE CREATED!!!");
        this.permissionManager = permissionManager;
    }

    @Nullable
    private MethodChannel channel;

    public StoreHelper findHelper(final long id){
        final String toFind = String.valueOf(id);
        for(final String key: stored.keySet()){
            if((toFind+"").equals(stored.get(key).id+"")) return  stored.get(key);
        }
        return null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        final StoreHelper helper = new StoreHelper(call, result);
        stored.put(call.argument("key"), helper);
        switch (call.method) {
            case "checkPermission":
                onCheckPermission(helper.result);
                break;
            case "requestPermission":
                onRequestPermission(helper, true);
                break;
            case "onStartDownloadingFile":
            case "downloadFile":
                onStartDownloadingFile(helper);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    void startListening(Context context, BinaryMessenger messenger) {
        if (channel != null) {
            Log.w(TAG, "Setting a method call handler before the last was disposed.");
            stopListening();
        }

        channel = new MethodChannel(messenger, CHANNEL);
        channel.setMethodCallHandler(this);
        this.context = context;
    }

    void stopListening() {
        if (channel == null) {
            Log.d(TAG, "Tried to stop listening when no MethodChannel had been initialized.");
            return;
        }

        channel.setMethodCallHandler(null);
        channel = null;
    }

    void setActivity(@Nullable Activity activity) {
        this.activity = activity;
    }

    private void onCheckPermission(MethodChannel.Result result) {
        try {
            StoragePermission permission = permissionManager.checkPermissionStatus(context);
            result.success(permission.toInt());
        } catch (PermissionUndefinedException e) {
            ErrorCodes errorCode = ErrorCodes.permissionDefinitionsNotFound;
            result.error(errorCode.toString(), errorCode.toDescription(), null);
        }
    }

    private void onRequestPermission(StoreHelper helper, final boolean sendResult) {
        try {
            permissionManager.requestPermission(
                    activity,
                    new PermissionResultCallback() {
                        @Override
                        public void onResult(StoragePermission permission) {
                            if (sendResult) {
                                helper.result.success(permission.toInt());
                                stored.remove(helper.call.argument("key"));
                            }
                            else {
                                if (permission != StoragePermission.always) {
                                    ErrorCodes errorCode = ErrorCodes.permissionDenied;
                                    helper.result.error(errorCode.toString(), errorCode.toDescription(), null);
                                    stored.remove(helper.call.argument("key"));
                                } else
                                    onMethodCall(helper.call, helper.result);
                            }
                        }
                    },
                    (ErrorCodes errorCode) ->
                            helper.result.error(errorCode.toString(), errorCode.toDescription(), null));
        } catch (PermissionUndefinedException e) {
            ErrorCodes errorCode = ErrorCodes.permissionDefinitionsNotFound;
            helper.result.error(errorCode.toString(), errorCode.toDescription(), null);
        }
    }

    private void onStartDownloadingFile(StoreHelper helper) {
        try {
            if (!permissionManager.hasPermission(context)) {
                onRequestPermission(helper, false);
                return;
            }
        } catch (PermissionUndefinedException e) {
            helper.result.error(
                    ErrorCodes.permissionDefinitionsNotFound.toString(),
                    ErrorCodes.permissionDefinitionsNotFound.toDescription(),
                    null);
            return;
        }

        Map<String, Object> map = (Map<String, Object>) helper.call.arguments;
        lastURL = helper.call.argument("url");
        lastName = helper.call.argument("name");

        new DownloadTaskBuilder(activity)
                .setUrl(lastURL)
                .setName(lastName)
                .setCallbacks(new DownloadCallbacks() {
                    @Override
                    public void onIDReceived(long id) {
                        super.onIDReceived(id);
                        tasks.put(id, this);

                        final String onProgress = helper.call.argument("onidreceived");

                        Map<String, Object> args = new HashMap();

                        args.put("id", id);
                        args.put("url", helper.call.argument("url"));
                        args.put("key", helper.call.argument("key"));
                        stored.get(helper.call.argument("key")).id = String.valueOf(id);
                        channel.invokeMethod("onIDReceived", args);
                    }

                    @Override
                    public void onProgress(double progress) {
                        super.onProgress(progress);

                        final String onProgress = helper.call.argument("onprogress");

                        if (TextUtils.isEmpty(onProgress)) return;
                        Map<String, Object> args = new HashMap();

                        args.put("id", id);
                        args.put("progress", progress);
                        args.put("key", helper.call.argument("key"));
                        channel.invokeMethod("onProgress", args);
                    }

                    @Override
                    public void onProgress(String name, double progress) {
                        super.onProgress(name, progress);

                        final String onProgressWithName = helper.call.argument("onprogress_named");

                        if (TextUtils.isEmpty(onProgressWithName)) return;
                        Map<String, Object> args = new HashMap();

                        args.put("id", id);
                        args.put("name", name);
                        args.put("progress", progress);
                        args.put("key", helper.call.argument("key"));
                        channel.invokeMethod("onProgress", args);
                    }

                    @Override
                    public void onDownloadCompleted(String path) {
                        super.onDownloadCompleted(path);

                        final String onDownloadCompleted = helper.call.argument("ondownloadcompleted");

                        if (TextUtils.isEmpty(onDownloadCompleted)) return;
                        Map<String, Object> args = new HashMap();

                        args.put("id", id);
                        args.put("path", path);
                        args.put("key", helper.call.argument("key"));
                        channel.invokeMethod("onDownloadCompleted", args);
                    }

                    @Override
                    public void onDownloadError(String errorMessage) {
                        super.onDownloadError(errorMessage);
                        final String onDownloadError = helper.call.argument("ondownloaderror");

                        if (TextUtils.isEmpty(onDownloadError)) return;
                        Map<String, Object> args = new HashMap();

                        args.put("id", id);
                        args.put("error", errorMessage);
                        args.put("key", helper.call.argument("key"));
                        channel.invokeMethod("onDownloadError", args);
                    }
                })
                .build()
                .startDownloading();
    }

    public void removeTask(final long id) {
        tasks.remove(id);
    }

    public DownloadCallbacks getTask(final long id) {
        return tasks.get(id);
    }
}
