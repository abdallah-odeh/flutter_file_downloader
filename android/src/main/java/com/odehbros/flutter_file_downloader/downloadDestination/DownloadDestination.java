package com.odehbros.flutter_file_downloader.downloadDestination;

import java.io.File;

abstract public class DownloadDestination {
    public final String subPath;

    public DownloadDestination() {
        subPath = null;
    }

    public DownloadDestination(final String subPath) {
        this.subPath = subPath;
    }

    public abstract File getDirectoryPath();
}
