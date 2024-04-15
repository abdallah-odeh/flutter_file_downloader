package com.odehbros.flutter_file_downloader.downloadDestination;

import android.os.Environment;

import java.io.File;

public class AppData extends DownloadDestination {
    @Override
    public File getDirectoryPath() {
        return Environment.getDataDirectory();
    }
}
