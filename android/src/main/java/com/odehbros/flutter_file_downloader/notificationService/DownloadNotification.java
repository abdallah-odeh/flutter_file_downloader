package com.odehbros.flutter_file_downloader.notificationService;

import android.Manifest;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;

import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import java.util.Locale;
import java.util.Random;

public class DownloadNotification {

    //Processing download notification id
    final int PR_DOWNLOAD_NOTIFICATION_ID;// = 251997;
    //Done download notification id
    final int DO_DOWNLOAD_NOTIFICATION_ID;
    static final String PROGRESS_CHANNEL_ID = "DOWNLOADING_CHANNEL";
    static final String DONE_DOWNLOADING_CHANNEL_ID = "DOWNLOAD_DONE_CHANNEL";

    final Context context;
    String fileName;
    final NotificationTexts texts;

    public DownloadNotification(final Context context, final String fileName, NotificationTexts texts) {
        this.context = context;
        this.fileName = fileName;
        this.texts = texts;

        PR_DOWNLOAD_NOTIFICATION_ID = new Random().nextInt();
        DO_DOWNLOAD_NOTIFICATION_ID = PR_DOWNLOAD_NOTIFICATION_ID + 1;
    }

    public void setFileName(final String fileName) {
        this.fileName = fileName;
    }

    public void populateProgress(final double progress) {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            return;
        }
        NotificationManagerCompat notificationManagerCompat = NotificationManagerCompat.from(context);

//        notificationManagerCompat.cancel(DOWNLOAD_NOTIFICATION_ID);

        Intent notifyIntent = new Intent();
        PendingIntent notifyPendingIntent = PendingIntent.getActivity(
                context,
                PR_DOWNLOAD_NOTIFICATION_ID,
                notifyIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        NotificationCompat.Builder notificationBuilder = createNotificationBuilder(PROGRESS_CHANNEL_ID);
        notificationBuilder.setContentIntent(notifyPendingIntent);
        notificationBuilder.setTicker("Start downloading from the server");
        notificationBuilder.setOngoing(true);
        notificationBuilder.setAutoCancel(false);
        notificationBuilder.setSilent(false);
        notificationBuilder.setSmallIcon(android.R.drawable.stat_sys_download);
        notificationBuilder.setContentTitle(fileName);
        notificationBuilder.setContentText(String.format(Locale.ENGLISH, "Downloading %2.1f%%", progress));
        notificationBuilder.setProgress(100, (int) progress, false);
        try {
            notificationManagerCompat.notify(PR_DOWNLOAD_NOTIFICATION_ID, notificationBuilder.build());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void populateDownloadResult(final boolean success) {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            return;
        }
        String statusText = success ? texts.getDownloadComplete() : texts.getDownloadFailed();
        int resId = success ? android.R.drawable.stat_sys_download_done : android.R.drawable.stat_notify_error;

        NotificationManagerCompat notificationManagerCompat = NotificationManagerCompat.from(context);

        notificationManagerCompat.cancel(PR_DOWNLOAD_NOTIFICATION_ID);

        NotificationCompat.Builder notificationBuilder = createNotificationBuilder(DONE_DOWNLOADING_CHANNEL_ID);
        notificationBuilder.setContentTitle(fileName);
        notificationBuilder.setSmallIcon(resId);
        notificationBuilder.setOngoing(false);
        notificationBuilder.setAutoCancel(true);
        notificationBuilder.setContentText(statusText);
        notificationBuilder.setProgress(0, 0, false);
        try {
            notificationManagerCompat.notify(DO_DOWNLOAD_NOTIFICATION_ID, notificationBuilder.build());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private NotificationCompat.Builder createNotificationBuilder(String channelId) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            String channelName = "File downloader";
            NotificationChannel notificationChannel;
            final boolean isProgressNotification = channelId.equals(PROGRESS_CHANNEL_ID);
            if (isProgressNotification) {
                //only change channel importance to avoid sending sound with notification
                notificationChannel = new NotificationChannel(
                        channelId,
                        channelName,
                        NotificationManager.IMPORTANCE_LOW);
            } else {
                notificationChannel = new NotificationChannel(
                        channelId,
                        channelName,
                        NotificationManager.IMPORTANCE_DEFAULT);
            }
            notificationChannel.setLightColor(Color.BLUE);
            notificationChannel.setLockscreenVisibility(Notification.VISIBILITY_PRIVATE);
            NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (notificationManager != null) {
                notificationManager.createNotificationChannel(notificationChannel);
            }
        }
        return new NotificationCompat.Builder(context, channelId);
    }
}
