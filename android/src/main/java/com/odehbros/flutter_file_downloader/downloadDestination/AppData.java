package com.odehbros.flutter_file_downloader.downloadDestination;

import android.os.Environment;

import java.io.File;

public class AppData extends DownloadDestination {
    public AppData() {
    }

    public AppData(final String subPath) {
        super(subPath);
    }

    @Override
    public File getDirectoryPath() {
        return Environment.getDataDirectory();
    }
}
