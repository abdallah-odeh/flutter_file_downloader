package com.odehbros.flutter_file_downloader.fileStore;

import android.text.TextUtils;

import com.odehbros.flutter_file_downloader.PluginLogger;
import com.odehbros.flutter_file_downloader.core.DownloadCallbacks;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Locale;

public class FileStoreHandler {

    public File writeFile(
            final String content,
            final String directory,
            final String name,
            final String extension,
            final DownloadCallbacks callbacks) {

        PluginLogger.log("Writing to file " + directory + "/" + name + "." + extension);

        final byte[] imgBytesData = android.util.Base64.decode(
                content,
                android.util.Base64.DEFAULT);

        FileOutputStream fileOutputStream = null;
        File file = null;

        final String fileName = String.format(
                "%s.%s",
                name,
                extension.replace(".", ""));

        callbacks.onProgress(fileName, 0);

        try {
            file = new File(createFile(directory, name, extension));
            callbacks.onProgress(fileName, 20);
            fileOutputStream = new FileOutputStream(file);
            callbacks.onProgress(fileName, 40);
        } catch (Exception e) {
            e.printStackTrace();
            callbacks.onDownloadError(e.getLocalizedMessage());
            return null;
        }

        final BufferedOutputStream bufferedOutputStream = new BufferedOutputStream(
                fileOutputStream);
        callbacks.onProgress(fileName, 60);
        try {
            bufferedOutputStream.write(imgBytesData);
            callbacks.onProgress(fileName, 80);
        } catch (IOException e) {
            e.printStackTrace();
            callbacks.onDownloadError(e.getLocalizedMessage());
            return null;
        } finally {
            callbacks.onProgress(fileName, 100);
            try {
                bufferedOutputStream.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
            callbacks.onDownloadCompleted(file.getPath());
        }
        return file;
    }

    public String createFile(String directory, String subPath, String name, final String extension) throws IOException {
        if (TextUtils.isEmpty(subPath)) {
            return createFile(
                    directory,
                    name,
                    extension);
        }
        subPath = FileUtils.fixSubPath(subPath);
        return createFile(
                String.format("%s/%s", directory, subPath),
                name,
                extension);
    }

    public String createFile(final String directory, final String name, final String extension) throws IOException {
        String path = String.format("%s/%s", directory, name);
        final String[] splitted = name.split("\\.");
        final String extension2 = splitted[splitted.length - 1];
        final String fileName = name.replaceAll("." + extension, "").replaceAll("." + extension2, "");
        if (!FileUtils.createDir(directory)) {
            PluginLogger.log("Create directories " + directory + " failed!");
            return null;
        }
        int instanceNo = 0;
        String ext = extension;
        if (TextUtils.isEmpty(extension)) ext = extension2;
        if (TextUtils.isEmpty(extension2)) {
            PluginLogger.log("Could not detect file extension for file " + name);
        }
        do {
            File file = new File(path);
            if (file.exists()) {
                instanceNo++;
                path = String.format(Locale.ENGLISH,
                        "%s/%s-%d.%s",
                        directory,
                        fileName.replaceAll("." + ext, ""),
                        instanceNo,
                        ext
                );
                continue;
            }
            if (file.createNewFile()) {
                return path;
            } else {
                return null;
            }
        } while (true);
    }
}
