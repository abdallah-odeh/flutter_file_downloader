package com.odehbros.flutter_file_downloader.core;

import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import android.database.Cursor;
import android.os.Environment;

import com.odehbros.flutter_file_downloader.MethodCallHandlerImpl;
import com.odehbros.flutter_file_downloader.StoreHelper;

public class DownloadCompleterBroadcast extends BroadcastReceiver {

    final MethodCallHandlerImpl methodCallHandler;

    public DownloadCompleterBroadcast(final MethodCallHandlerImpl methodCallHandler) {
        this.methodCallHandler = methodCallHandler;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        if (action.equals(DownloadManager.ACTION_DOWNLOAD_COMPLETE)) {
            try {
                DownloadManager.Query query = new DownloadManager.Query();
                final long id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, 0);
                query.setFilterById(id);
                DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
                Cursor cursor = manager.query(query);
                if (cursor.moveToFirst()) {
                    if (cursor.getCount() > 0) {
                        int status = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_STATUS));
                        if (status == DownloadManager.STATUS_SUCCESSFUL) {
                            final DownloadCallbacks task = methodCallHandler.getTask(id);
                            String downloadPath = cursor.getString(cursor.getColumnIndex(DownloadManager.COLUMN_LOCAL_URI));
                            downloadPath = downloadPath.replace("file://", "");
                            if (task != null) {
                                task.onDownloadCompleted(downloadPath);
                            }
                            final StoreHelper helper = methodCallHandler.findHelper(id);
                            if (helper != null) {
                                helper.result.success(downloadPath);
                            } else {
                                Log.e("COULD NOT FIND HELPER WITH KEY", id + "");
                            }
                        } else {
                            int columnIndex = cursor.getColumnIndex(DownloadManager.COLUMN_REASON);
                            if (columnIndex > -1) {
                                int message = cursor.getInt(columnIndex);

                                final DownloadCallbacks task = methodCallHandler.getTask(id);
                                if (task != null)
                                    task.onDownloadError(message + "");

                                final StoreHelper helper = methodCallHandler.findHelper(id);
                                if (helper != null)
                                    helper.result.error("Download file error", message + "", null);
                            }
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
