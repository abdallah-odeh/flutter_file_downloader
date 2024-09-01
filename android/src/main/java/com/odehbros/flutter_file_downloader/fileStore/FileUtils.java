package com.odehbros.flutter_file_downloader.fileStore;

import com.odehbros.flutter_file_downloader.PluginLogger;

import java.io.File;

public class FileUtils {

    public static boolean createDir(final String path) {
        final File file = new File(path);
        if (file.exists()) {
            PluginLogger.log("Tried to create the dir " + path + " but it's already created!");
            return true;
        }
        final boolean dirsCreated = file.mkdirs();
        if (dirsCreated) {
            PluginLogger.log("Created the dir " + path + " successfully");
        } else {
            PluginLogger.log("Could not create the dir " + path + "!");
        }
        return dirsCreated;
    }

    public static String fixSubPath(String subPath) {
        if (subPath == null) return "";
        if (subPath.isEmpty()) return "";
        if (!subPath.endsWith("/")) subPath = String.format("%s/", subPath);
        if (subPath.startsWith("/")) return subPath.replaceFirst("/", "");
        return subPath;
    }
}
