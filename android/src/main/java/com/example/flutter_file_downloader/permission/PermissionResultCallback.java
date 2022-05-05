package com.example.flutter_file_downloader.permission;

@FunctionalInterface
public interface PermissionResultCallback {
    public void onResult(StoragePermission permission);
}
