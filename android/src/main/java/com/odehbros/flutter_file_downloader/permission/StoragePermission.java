package com.odehbros.flutter_file_downloader.permission;

public enum StoragePermission {
    /// Permission to access the storage is denied by the user.
    denied,
    /// Permission to access the storage is denied for ever. The
    /// permission dialog will not been shown again until the user updates
    /// the permission in the App settings.
    deniedForever,
    /// Permission to access the storage is allowed
    always;

    public int toInt() {
        switch (this) {
            case denied:
                return 0;
            case deniedForever:
                return 1;
            case always:
                return 2;
            default:
                throw new IndexOutOfBoundsException();
        }
    }
}
