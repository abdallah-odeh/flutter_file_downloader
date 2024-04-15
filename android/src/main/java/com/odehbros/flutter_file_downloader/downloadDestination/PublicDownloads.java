package com.odehbros.flutter_file_downloader.downloadDestination;

import android.os.Environment;

import java.io.File;

public class PublicDownloads extends DownloadDestination {
    @Override
    public File getDirectoryPath() {
        return Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
    }
}
