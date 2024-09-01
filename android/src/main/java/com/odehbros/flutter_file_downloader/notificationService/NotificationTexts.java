package com.odehbros.flutter_file_downloader.notificationService;

public class NotificationTexts {
    private String downloadComplete;
    private String downloadProgress;
    private String downloadFailed;

    public static NotificationTexts defaultText() {
        final NotificationTexts texts = new NotificationTexts();

        texts.setDownloadComplete("Download completed.");
        texts.setDownloadProgress("Downloading ...");
        texts.setDownloadFailed("Download failed.");

        return texts;
    }

    public static NotificationTexts empty() {
        return new NotificationTexts();
    }

    public String getDownloadComplete() {
        return downloadComplete;
    }

    public void setDownloadComplete(String downloadComplete) {
        this.downloadComplete = downloadComplete;
    }

    public String getDownloadProgress() {
        return downloadProgress;
    }

    public void setDownloadProgress(String downloadProgress) {
        this.downloadProgress = downloadProgress;
    }

    public String getDownloadFailed() {
        return downloadFailed;
    }

    public void setDownloadFailed(String downloadFailed) {
        this.downloadFailed = downloadFailed;
    }
}
