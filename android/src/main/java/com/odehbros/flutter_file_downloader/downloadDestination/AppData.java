package com.odehbros.flutter_file_downloader.downloadDestination;

import android.app.Activity;
import android.os.Environment;

import java.io.File;
import io.flutter.util.PathUtils;

public class AppData extends DownloadDestination {
    final Activity activity;
    public AppData(final Activity activity) {
        this.activity = activity;
    }

    public AppData(final Activity activity, final String subPath) {
        super(subPath);

        this.activity = activity;
    }

    @Override
    public File getDirectoryPath() {
        if (true) {
            return new File(PathUtils.getFilesDir(activity));
        }
        return Environment.getDataDirectory();
    }
}
