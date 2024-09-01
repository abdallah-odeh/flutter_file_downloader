package com.odehbros.flutter_file_downloader.downloader;

import android.app.Activity;
import android.net.Uri;
import android.text.TextUtils;

import com.odehbros.flutter_file_downloader.StoreHelper;
import com.odehbros.flutter_file_downloader.core.DownloadCallbacks;
import com.odehbros.flutter_file_downloader.core.DownloadNotificationType;
import com.odehbros.flutter_file_downloader.core.DownloadRequestMethodType;
import com.odehbros.flutter_file_downloader.downloadDestination.DownloadDestination;
import com.odehbros.flutter_file_downloader.fileStore.FileStoreHandler;

import java.util.List;
import java.util.Map;

abstract public class DownloadService {

    final Activity activity;
    final String url;
    final String name;
    final DownloadNotificationType notifications;
    final DownloadDestination downloadDestination;
    final DownloadCallbacks callbacks;
    final Map<String, String> headers;
    private boolean isDownloading;
    final StoreHelper task;
    protected final FileStoreHandler fileStoreHandler = new FileStoreHandler();

    public DownloadService(Activity activity, String url, String name, DownloadNotificationType notifications, DownloadDestination downloadDestination, DownloadCallbacks callbacks, Map<String, String> requestHeaders, StoreHelper helper) {
        this.activity = activity;
        this.url = url;
        this.name = name;
        this.notifications = notifications;
        this.downloadDestination = downloadDestination;
        this.callbacks = callbacks;
        this.headers = requestHeaders;
        this.task = helper;
    }

    public void startDownload() {
        appendHeaders();
        handleNotificationsStatus();

        download();
    }

    protected abstract void download();

    public String getFileNameFromContent(final String contentDisposition) {
        try {
            if (TextUtils.isEmpty(contentDisposition)) return null;
            final String[] parts = contentDisposition.split(" ");
            return parts[1].replaceFirst("filename=", "");
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    public String getFileName() {
        final Uri uri = Uri.parse(url);
        final List<String> path = uri.getPathSegments();
        final String originalName = path.get(path.size() - 1);

        return getDownloadFileName(name, originalName);
    }

    public void setRequestMethod(final DownloadRequestMethodType methodType) {
    }

    public abstract boolean cancelDownload(final long id);

    protected abstract void appendHeaders();

    protected abstract void handleNotificationsStatus();

    private String getDownloadFileName(final String sentName, final String originalName) {
        String name = null;
        String extension = null;

        if (!TextUtils.isEmpty(sentName)) {
            name = extractFileName(sentName);
        }

        if (TextUtils.isEmpty(name)) {
            name = extractFileName(originalName);
        }

        // Get file extension from the URL e.g. https://myurl.com/file.pdf
        extension = getExtensionFrom(originalName);

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
}
