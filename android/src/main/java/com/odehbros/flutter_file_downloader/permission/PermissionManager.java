package com.odehbros.flutter_file_downloader.permission;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.odehbros.flutter_file_downloader.errors.ErrorCallback;
import com.odehbros.flutter_file_downloader.errors.ErrorCodes;
import com.odehbros.flutter_file_downloader.errors.PermissionUndefinedException;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@SuppressWarnings("deprecation")
public class PermissionManager
        implements io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener {

    private static final int PERMISSION_REQUEST_CODE = 109;

    @Nullable
    private Activity activity;
    @Nullable
    private ErrorCallback errorCallback;
    @Nullable
    private PermissionResultCallback resultCallback;

    public StoragePermission checkPermissionStatus(Context context)
            throws PermissionUndefinedException {
        // if the targetSdkVersion was set to 33+, then there is no need to request the permission as it's already granted
        if (getTargetSdkVersion(context) >= Build.VERSION_CODES.TIRAMISU) {
            return StoragePermission.always;
        }

        List<String> permissions = getStoragePermissionsFromManifest(context);

        int permissionStatus = PackageManager.PERMISSION_DENIED;

        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(context, permission)
                    == PackageManager.PERMISSION_GRANTED) {
                permissionStatus = PackageManager.PERMISSION_GRANTED;
                break;
            }
        }

        if (permissionStatus == PackageManager.PERMISSION_DENIED) {
            return StoragePermission.denied;
        }

        return StoragePermission.always;
    }

    public void requestPermission(
            Activity activity, PermissionResultCallback resultCallback, ErrorCallback errorCallback)
            throws PermissionUndefinedException {

        if (activity == null) {
            errorCallback.onError(ErrorCodes.activityMissing);
            return;
        }

        // Before Android M, requesting permissions was not needed.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            resultCallback.onResult(StoragePermission.always);
            return;
        }

        final List<String> permissionsToRequest = getStoragePermissionsFromManifest(activity);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
                && PermissionUtils.hasPermissionInManifest(
                activity, Manifest.permission.WRITE_EXTERNAL_STORAGE)) {
            final StoragePermission permissionStatus = checkPermissionStatus(activity);
            if (permissionStatus == StoragePermission.always) {
                permissionsToRequest.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
            }
        }

        this.errorCallback = errorCallback;
        this.resultCallback = resultCallback;
        this.activity = activity;

        ActivityCompat.requestPermissions(
                activity, permissionsToRequest.toArray(new String[0]), PERMISSION_REQUEST_CODE);
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
            requestedPermissions = getStoragePermissionsFromManifest(this.activity);
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

        StoragePermission storagePermission = StoragePermission.denied;
        int grantedResult = PackageManager.PERMISSION_DENIED;
        boolean shouldShowRationale = false;
        boolean permissionsPartOfPermissionsResult = false;

        for (String permission : requestedPermissions) {
            int requestedPermissionIndex = indexOf(permissions, permission);
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
            storagePermission = StoragePermission.always;
        } else {
            if (!shouldShowRationale) {
                storagePermission = StoragePermission.deniedForever;
            }
        }

        if (this.resultCallback != null) {
            this.resultCallback.onResult(storagePermission);
        }

        return true;
    }

    @RequiresApi(api = Build.VERSION_CODES.Q)
    private boolean hasBackgroundAccess(String[] permissions, int[] grantResults) {
        int backgroundPermissionIndex =
                indexOf(permissions, Manifest.permission.WRITE_EXTERNAL_STORAGE);
        return backgroundPermissionIndex >= 0
                && grantResults[backgroundPermissionIndex] == PackageManager.PERMISSION_GRANTED;
    }

    private static <T> int indexOf(T[] arr, T val) {
        return Arrays.asList(arr).indexOf(val);
    }

    private static List<String> getStoragePermissionsFromManifest(Context context)
            throws PermissionUndefinedException {
        boolean writeStoragePermissionExists =
                PermissionUtils.hasPermissionInManifest(context, Manifest.permission.WRITE_EXTERNAL_STORAGE);

        if (!writeStoragePermissionExists) {
            throw new PermissionUndefinedException();
        }

        List<String> permissions = new ArrayList<>();

        if (writeStoragePermissionExists) {
            permissions.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
        }

        return permissions;
    }

    public boolean hasPermission(Context context) throws PermissionUndefinedException {
        StoragePermission StoragePermission = this.checkPermissionStatus(context);

        return StoragePermission == StoragePermission.always;
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
