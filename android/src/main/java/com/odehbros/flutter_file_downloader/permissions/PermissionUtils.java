package com.odehbros.flutter_file_downloader.permissions;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;

import com.odehbros.flutter_file_downloader.errors.PermissionUndefinedException;

import java.util.ArrayList;
import java.util.List;
import android.Manifest;

public class PermissionUtils {

    public static boolean hasPermissionInManifest(Context context, String permission) {
        try {
            final PackageInfo info =
                    context
                            .getPackageManager()
                            .getPackageInfo(context.getPackageName(), PackageManager.GET_PERMISSIONS);
            if (info.requestedPermissions != null) {
                for (String p : info.requestedPermissions) {
                    if (p.equals(permission)) {
                        return true;
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return false;
    }


    public static List<String> getStoragePermissionsFromManifest(Context context)
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
}
