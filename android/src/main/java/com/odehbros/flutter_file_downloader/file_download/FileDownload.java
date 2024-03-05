package com.odehbros.flutter_file_downloader.file_download;

import android.text.TextUtils;
import java.util.List;
import java.util.Map;

abstract class FileDownload {


    private String fixDownloadFileName(final String name) {
        return name
                .replace("#", "")
                .replace("%", "")
                .replace("*", "")
                .replace(".", "")
                .replace("\\", "")
                .replace("|", "")
                .replace("\"", "")
                .replace(":", "")
                .replace("/", "")
                .replace("<", "")
                .replace(">", "")
                .replace("?", "")
                .replace("&", "");
    }

    private String getDownloadFileName(final String sentName, final String originalName) {
        String name = null;
        String extension = null;

        if (!TextUtils.isEmpty(sentName)) {
            name = extractFileName(sentName);
//            extension = getExtensionFrom(sentName);
        }

        if (TextUtils.isEmpty(name)) {
            name = extractFileName(originalName);
        }

        // Get file extension from the URL e.g. https://myurl.com/file.pdf
        extension = getExtensionFrom(originalName);
//        final String realExtension = getExtensionFrom(originalName);
//        if (TextUtils.isEmpty(extension) || !realExtension.equals(extension)) {
//            extension = realExtension;
//        }

//        return name;

        // If the URL does not contain file extension
        // e.g. https://myurl.com/myfile
        // then we try to extract it from the sent custom name if passed
        if (extension == null) {
            extension = getExtensionFrom(sentName);
        }

        // If no extension is provided neither in URL or custom file name,
        // we download the file without extension (might lead to improper file opening)
        if (extension == null) {
            return name;
        }

        // otherwise, we append the extension to file name
        return String.format("%s.%s", name, extension);
    }

    private String getExtensionFrom(final String name) {
        if (name == null) return null;
        final String[] arr = name.split("\\.");
        if (arr.length == 1) return null;
        return arr[arr.length - 1];
    }

    private String extractFileName(final String name) {
        final String[] terms = name.split("\\.");
        return fixDownloadFileName(terms[0]);
    }
}