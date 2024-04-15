package com.odehbros.flutter_file_downloader.core;

public enum DownloadNotificationType {

    /**
     * Shows all notifications, including Download completed or download failed, ...
     */
    ALL,
    /**
     * Shows only a progress bar notification to indicate download progress
     */
    PROGRESS_ONLY,
    /**
     * Shows only a progress bar notification to notify about download result
     */
    COMPLETION_ONLY,

    /**
     * No notifications at all
     * this requires a permission to be included in the AndroidManifest.xml
     * android.permission.DOWNLOAD_WITHOUT_NOTIFICATION
     */
    OFF
}
