package com.odehbros.flutter_file_downloader.permissions;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import androidx.core.app.ActivityCompat;

import com.odehbros.flutter_file_downloader.errors.ErrorCallback;
import com.odehbros.flutter_file_downloader.errors.ErrorCodes;
import com.odehbros.flutter_file_downloader.errors.PermissionUndefinedException;

import java.util.Arrays;
import java.util.List;
import java.util.Objects;

import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;

public class PermissionHandler implements RequestPermissionsResultListener {

    private  Activity activity;

    private PermissionResultCallback resultCallback;
    private ErrorCallback errorCallback;
    private static final int PERMISSION_REQUEST_CODE = 8137;

    static final String WRITE_EXTERNAL_STORAGE = Manifest.permission.WRITE_EXTERNAL_STORAGE;
    static final String POST_NOTIFICATIONS = Manifest.permission.POST_NOTIFICATIONS;

    public PermissionHandler(){}

    public void setActivity(final Activity activity) {
        this.activity = activity;
    }

    @Override
    public boolean onRequestPermissionsResult(
            int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode != PERMISSION_REQUEST_CODE) {
            return false;
        }

        if (this.activity == null) {
            if (this.errorCallback != null) {
                this.errorCallback.onError(ErrorCodes.activityMissing);
            }
            return false;
        }

        List<String> requestedPermissions;

        try {
            requestedPermissions = PermissionUtils.getStoragePermissionsFromManifest(this.activity);
        } catch (PermissionUndefinedException ex) {
            if (this.errorCallback != null) {
                this.errorCallback.onError(ErrorCodes.permissionDefinitionsNotFound);
            }

            return false;
        }

        if (grantResults.length == 0) {
            Log.i(
                    "FlutterFileDownloader",
                    "The grantResults array is empty. This can happen when the user cancels the permission request");
            return false;
        }

        PermissionStatus storagePermission = PermissionStatus.denied;
        int grantedResult = PackageManager.PERMISSION_DENIED;
        boolean shouldShowRationale = false;
        boolean permissionsPartOfPermissionsResult = false;

        for (String permission : requestedPermissions) {
            int requestedPermissionIndex = Arrays.asList(permissions).indexOf(permission);
            if (requestedPermissionIndex >= 0) {
                permissionsPartOfPermissionsResult = true;
            }
            if (grantResults[requestedPermissionIndex] == PackageManager.PERMISSION_GRANTED) {
                grantedResult = PackageManager.PERMISSION_GRANTED;
            }
            if (ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)) {
                shouldShowRationale = true;
            }
        }

        if (!permissionsPartOfPermissionsResult) {
            Log.w(
                    "FlutterFileDownloader",
                    "Storage permissions not part of permissions send to onRequestPermissionsResult method.");
            return false;
        }

        if (grantedResult == PackageManager.PERMISSION_GRANTED) {
            storagePermission = PermissionStatus.always;
        } else {
            if (!shouldShowRationale) {
                storagePermission = PermissionStatus.deniedForever;
            }
        }

        if (this.resultCallback != null) {
            this.resultCallback.onResult(storagePermission);
        }

        return true;
    }

    public void requestPermissions(PermissionResultCallback resultCallback, ErrorCallback errorCallback) throws PermissionUndefinedException {
        if (activity == null) {
            errorCallback.onError(ErrorCodes.activityMissing);
            return;
        }

        this.errorCallback = errorCallback;
        this.resultCallback = resultCallback;

        requestStoragePermission();
        requestPostNotificationsPermissions();
    }

    private void requestPostNotificationsPermissions() {
        if (hasPermission(POST_NOTIFICATIONS) == PermissionStatus.always) return;

        requestPermission(new String[]{POST_NOTIFICATIONS});
    }

    private void requestStoragePermission() {
        // Before Android M, requesting permissions was not needed.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return;

        if (getTargetSdkVersion(activity) >= Build.VERSION_CODES.TIRAMISU) return;

        if (hasPermission(WRITE_EXTERNAL_STORAGE) == PermissionStatus.always) return;

        requestPermission(new String[]{WRITE_EXTERNAL_STORAGE});
    }

    private void requestPermission(final String[] permissions) {
        ActivityCompat.requestPermissions(
                activity,
                permissions,
                PERMISSION_REQUEST_CODE);
    }

    public PermissionStatus hasPermission(final String permission) {
        if (Objects.equals(permission, WRITE_EXTERNAL_STORAGE)) {
            if (getTargetSdkVersion(activity) >= Build.VERSION_CODES.TIRAMISU) {
                return PermissionStatus.always;
            }
        }
        final boolean granted = ActivityCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED;

        if (granted) {
            return PermissionStatus.always;
        }

        if (PermissionUtils.hasPermissionInManifest(activity, permission)) {
            return PermissionStatus.denied;
        }

        return PermissionStatus.deniedForever;
    }

    private int getTargetSdkVersion(final Context context) {
        final String packageName = context.getPackageName();
        final PackageManager packageManager = context.getPackageManager();
        try {
            final ApplicationInfo applicationInfo = packageManager.getApplicationInfo(packageName, 0);
            return applicationInfo.targetSdkVersion;
        } catch (PackageManager.NameNotFoundException e) {
            return -1;
        }
    }
}
