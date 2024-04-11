package com.odehbros.flutter_file_downloader;

import android.app.DownloadManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.content.ServiceConnection;
import android.os.IBinder;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.odehbros.flutter_file_downloader.permission.PermissionManager;
import com.odehbros.flutter_file_downloader.core.DownloadCompleterBroadcast;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

/**
 * FlutterFileDownloaderPlugin
 */
public class FlutterFileDownloaderPlugin implements FlutterPlugin, ActivityAware {

    private static final String TAG = "FlutterFileDownloader";
    private final PermissionManager permissionManager;

    @Nullable
    private MethodCallHandlerImpl methodCallHandler;
    @Nullable
    private ActivityPluginBinding pluginBinding;
    @Nullable
    private DownloadCompleterBroadcast onDownloadCompleted;

    public FlutterFileDownloaderPlugin() {
        permissionManager = new PermissionManager();
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        methodCallHandler = new MethodCallHandlerImpl(this.permissionManager);
        methodCallHandler.startListening(
                flutterPluginBinding.getApplicationContext(),
                flutterPluginBinding.getBinaryMessenger());
        onDownloadCompleted = new DownloadCompleterBroadcast(methodCallHandler);
        bindForegroundService(flutterPluginBinding.getApplicationContext());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        unbindForegroundService(binding.getApplicationContext());
        dispose();
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.pluginBinding = binding;
        registerListeners();
        if (methodCallHandler != null) {
            methodCallHandler.setActivity(binding.getActivity());
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        deregisterListeners();
        if (methodCallHandler != null) {
            methodCallHandler.setActivity(null);
        }
        if (pluginBinding != null) {
            pluginBinding = null;
        }
    }

    private void registerListeners() {
        if (pluginBinding != null) {
            pluginBinding.addRequestPermissionsResultListener(this.permissionManager);
        }
    }

    private void deregisterListeners() {
        if (pluginBinding != null) {
            pluginBinding.removeRequestPermissionsResultListener(this.permissionManager);
        }
    }

    private void bindForegroundService(Context context) {
        final IntentFilter filter = new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE);
        if (Build.VERSION.SDK_INT >= 34 && context.getApplicationInfo().targetSdkVersion >= 34) {
            context.registerReceiver(onDownloadCompleted, filter, Context.RECEIVER_EXPORTED);
        } else {
            context.registerReceiver(onDownloadCompleted, filter);
        }
    }

    private void unbindForegroundService(Context context) {
        context.unregisterReceiver(onDownloadCompleted);
    }

    private void dispose() {
        if (methodCallHandler != null) {
            methodCallHandler.stopListening();
            methodCallHandler.setActivity(null);
            methodCallHandler = null;
        }
    }
}
