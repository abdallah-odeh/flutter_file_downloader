package com.odehbros.flutter_file_downloader.downloader;

import android.app.Activity;
import android.os.StrictMode;
import android.text.TextUtils;

import com.odehbros.flutter_file_downloader.MethodCallHandlerImpl;
import com.odehbros.flutter_file_downloader.PluginLogger;
import com.odehbros.flutter_file_downloader.StoreHelper;
import com.odehbros.flutter_file_downloader.core.DownloadCallbacks;
import com.odehbros.flutter_file_downloader.core.DownloadNotificationType;
import com.odehbros.flutter_file_downloader.core.DownloadRequestMethodType;
import com.odehbros.flutter_file_downloader.downloadDestination.DownloadDestination;
import com.odehbros.flutter_file_downloader.notificationService.DownloadNotification;
import com.odehbros.flutter_file_downloader.notificationService.NotificationTexts;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.net.HttpURLConnection;
import java.net.ProtocolException;
import java.net.SocketException;
import java.net.URL;
import java.util.Calendar;
import java.util.Map;

public class HttpDownload extends DownloadService {
    private URL url;
    private HttpURLConnection urlConnection;
    final DownloadNotification notification;
    final NotificationTexts notificationTexts;
    final MethodCallHandlerImpl methodCallHandler;

    public HttpDownload(Activity activity, String url, String name, DownloadNotificationType notifications, DownloadDestination downloadDestination, DownloadCallbacks callbacks, Map<String, String> requestHeaders, StoreHelper helper, MethodCallHandlerImpl methodCallHandler) {
        super(activity, url, name, notifications, downloadDestination, callbacks, requestHeaders, helper);
        this.methodCallHandler = methodCallHandler;
        notificationTexts = NotificationTexts.defaultText();

        notification = new DownloadNotification(activity, getFileName(), notificationTexts);

        initialize(url);
    }

    public HttpDownload(Activity activity, String url, String name, DownloadNotificationType notifications, DownloadDestination downloadDestination, DownloadCallbacks callbacks, Map<String, String> requestHeaders, StoreHelper helper, MethodCallHandlerImpl methodCallHandler, NotificationTexts notificationTexts) {
        super(activity, url, name, notifications, downloadDestination, callbacks, requestHeaders, helper);
        this.methodCallHandler = methodCallHandler;
        if (notificationTexts == null) {
            notificationTexts = NotificationTexts.defaultText();
        }
        this.notificationTexts = notificationTexts;

        notification = new DownloadNotification(activity, getFileName(), notificationTexts);

        initialize(url);
    }

    private void initialize(final String url) {
        StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();

        StrictMode.setThreadPolicy(policy);

        try {
            this.url = new URL(url);
            urlConnection = (HttpURLConnection) this.url.openConnection();
        } catch (Exception e) {
            e.printStackTrace();
        }

        System.out.println("URL: " + this.url);
        System.out.println("URL CONNECTION: " + this.urlConnection);
    }

    @Override
    protected void download() {
//        Thread thread = new Thread() {
//            @Override
//            public void run() {
//                boolean success;
//                try {
//                    PluginLogger.log("========== RESPONSE HEADERS ==========");
//                    for (final Map.Entry entry : urlConnection.getRequestProperties().entrySet()) {
//                        final String key = (String) entry.getKey();
//                        String value = "";
//                        for (final String val : (List<String>)entry.getValue()) {
//                            value = ", " + val;
//                        }
//                        value = value.replaceFirst(", ", "");
//
//                        PluginLogger.log(String.format("KEY: %s, VALUE: %s", key, value));
//                    }
//                    PluginLogger.log("========== RESPONSE HEADERS ==========");
//                    final String FILE_NAME = getFileName();
//                    String fileName;
//                    fileName = getFileNameFromContent(urlConnection.getHeaderField("content-disposition"));
//                    if (TextUtils.isEmpty(fileName)) {
//                        fileName = FILE_NAME;
//                    }
//
//                    final String tmpFilePath = fileStoreHandler.createFile(
//                            downloadDestination.getDirectoryPath().getAbsolutePath(),
//                            fileName + ".tmp");
//                    File tmpFile = new File(tmpFilePath);
//
//                    URLConnection conection = url.openConnection();
//                    conection.connect();
//                    int fileLength = conection.getContentLength();
//
//                    PluginLogger.log("DOWNLOAD FILE: " + fileName + " OF SIZE " + fileLength);
//
//                    // input stream to read file - with 8k buffer
//                    InputStream input = new BufferedInputStream(url.openStream(), 8192);
//
//                    // Output stream to write file
//
//                    OutputStream output = new FileOutputStream(tmpFile);
//
//                    byte data[] = new byte[1024];
//
//                    long total = 0;
//                    int count, tmpPercentage = 0;
//                    while ((count = input.read(data)) != -1) {
//                        total += count;
//                        output.write(data, 0, count);
//                        int percentage = (int) ((total * 100) / fileLength);
//                        if (percentage > tmpPercentage) {
//
//                            tmpPercentage = percentage;
//                        }
//                    }
//
//                    // flushing output
//                    output.flush();
//
//                    // closing streams
//                    output.close();
//                    input.close();
//
//                    // rename file but cut off .tmp
//                    File newFile = new File(fileName);
//                    success = tmpFile.renameTo(newFile);
//                } catch (Exception e) {
//                    success = false;
//                }
//
//
//            }
//        };
//        thread.start();

        new Thread() {
            @Override
            public void run() {
                final String FILE_NAME = getFileName();

                try {
                    String fileName;
                    try {
                        fileName = getFileNameFromContent(urlConnection.getHeaderField("content-disposition"));
                    } catch (Exception e) {
                        e.printStackTrace();
                        fileName = null;
                    }
                    if (TextUtils.isEmpty(fileName)) {
                        fileName = FILE_NAME;
                    }

                    BufferedInputStream in = new BufferedInputStream(urlConnection.getInputStream());
                    File tmpFile = new File(fileName + ".tmp");
                    final String filePath = fileStoreHandler.createFile(
                            downloadDestination.getDirectoryPath().getAbsolutePath(),
                            downloadDestination.subPath,
                            fileName);
                    String finalFileName = fileName;
                    activity.runOnUiThread(() -> {
                        callbacks.onIDReceived(Calendar.getInstance().getTimeInMillis());
                        callbacks.onProgress(finalFileName, 0);
                    });
                    updateNotificationFileNameFromPath(filePath);
                    PluginLogger.log("TMP FILE PATH: " + filePath);
                    FileOutputStream fileOutputStream = new FileOutputStream(filePath);
                    byte[] dataBuffer = new byte[1024];
                    int bytesRead;
                    double downloadedSize = 0.0;
                    double progress = 0;
                    final int size = urlConnection.getContentLength();
                    while ((bytesRead = in.read(dataBuffer, 0, 1024)) != -1) {
                        fileOutputStream.write(dataBuffer, 0, bytesRead);
                        downloadedSize += bytesRead;
                        progress = downloadedSize / size;
                        double finalProgress = progress;
                        activity.runOnUiThread(() -> callbacks.onProgress(finalFileName, finalProgress * 100));
                        notification.populateProgress(progress * 100);
                    }
                    activity.runOnUiThread(() -> {
                        callbacks.onDownloadCompleted(filePath);
                        if (task != null) {
                            task.result.success(filePath);
                        }
                    });
                    notification.populateDownloadResult(true);
                } catch (Exception e) {
//                    e.printStackTrace();
                    String message = e.getLocalizedMessage();
                    if (TextUtils.isEmpty(message)) message = e.toString();
                    if (e instanceof SocketException && "Socket closed".equals(message)) {
                        message = "Download was canceled";
                    } else if (e instanceof FileNotFoundException && HttpDownload.super.url.equals(message)) {
                        message = String.format("%s %s", message, "does not exist!");
                        message = String.valueOf(404);
                    }
                    String finalMessage = message;
                    activity.runOnUiThread(() -> {
                        callbacks.onDownloadError(finalMessage);
                        if (task != null) {
                            task.result.error("Download file error", finalMessage, null);
                        }
                    });
                    notification.populateDownloadResult(false);
                }
            }
        }.start();
    }

    @Override
    protected void appendHeaders() {
//        if (headers.isEmpty()) return;

        for (final Map.Entry header : headers.entrySet()) {
            urlConnection.setRequestProperty(
                    (String) header.getKey(),
                    (String) header.getValue()
            );
        }

//        System.out.println("REQUEST HEADERS: --------------------");
//        for (final Map.Entry entry: urlConnection.getRequestProperties().entrySet()) {
//            final String key = (String) entry.getKey();
//            final List<String> values = (List<String>) entry.getValue();
//            StringBuilder value = new StringBuilder();
//            for (final String val : values) {
//                value.append(", ").append(val);
//            }
//
//            System.out.printf("%s: %s%n", key, value.toString().replaceFirst(", ", ""));
//        }
//        System.out.println("REQUEST HEADERS: --------------------");
    }

    @Override
    protected void handleNotificationsStatus() {
        TODO:

        switch (notifications) {
            case OFF:
                break;
            case ALL:
                break;
            case PROGRESS_ONLY:
                break;
        }
    }

    @Override
    public void setRequestMethod(DownloadRequestMethodType methodType) {
        try {
            urlConnection.setRequestMethod(methodType.name());
        } catch (ProtocolException e) {
            e.printStackTrace();
        }
    }

    @Override
    public boolean cancelDownload(long id) {
        urlConnection.disconnect();
        return true;
    }

    private void updateNotificationFileNameFromPath(final String path) {
        if (TextUtils.isEmpty(path)) return;
        final String[] segments = path.split("/");
        final String fileName = segments[segments.length - 1];
        if (TextUtils.isEmpty(fileName)) return;
        PluginLogger.log("Update notification file name to " + fileName);
        notification.setFileName(fileName);
    }
}
