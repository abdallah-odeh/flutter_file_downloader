import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_file_downloader_example/preferences_manager.dart';
import 'package:flutter_file_downloader_example/sesstion_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool enabled = FileDownloader().isLogEnabled;
  final SessionSettings settings = SessionSettings();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enable logs',
            style: Theme.of(context).textTheme.headline6,
          ),
          Row(
            children: [
              Expanded(
                child: Text(enabled ? 'Enabled' : 'Disabled',
                    style: Theme.of(context).textTheme.subtitle1),
              ),
              const SizedBox(width: 16),
              Switch(
                  value: enabled,
                  onChanged: (value) {
                    setState(() => enabled = value);
                    FileDownloader.setLogEnabled(enabled);
                  })
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey, height: 1),
          const SizedBox(height: 32),
          Text(
            'Display Notifications',
            style: Theme.of(context).textTheme.headline6,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<NotificationType>(
            items: [
              for (final type in NotificationType.values) ...[
                DropdownMenuItem(
                    child: Text(convertCamelCaseToText(type.name)),
                    value: type),
              ]
            ],
            onChanged: (final NotificationType? type) {
              if (type == null) return;
              settings.setNotificationType(type);
            },
            isExpanded: true,
            value: settings.notificationType,
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10)),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey, height: 1),
          const SizedBox(height: 32),
          Text(
            'Download destination',
            style: Theme.of(context).textTheme.headline6,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<DownloadDestinations>(
            items: [
              for (final type in DownloadDestinations.values) ...[
                DropdownMenuItem(
                    child: Text(convertCamelCaseToText(type.name)),
                    value: type),
              ]
            ],
            onChanged: (final DownloadDestinations? destination) {
              if (destination == null) return;
              settings.setDownloadDestination(destination);
            },
            isExpanded: true,
            value: settings.downloadDestination,
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10)),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey, height: 1),
          const SizedBox(height: 32),
          Text(
            'Maximum parallel downloads',
            style: Theme.of(context).textTheme.headline6,
          ),
          Row(
            children: [
              Expanded(
                child: Text(settings.maximumParallelDownloads.toString(),
                    style: Theme.of(context).textTheme.subtitle1),
              ),
              const SizedBox(width: 16),
              IconButton(
                  onPressed: () {
                    setState(() {
                      settings.setMaximumParallelDownloads(settings.maximumParallelDownloads - 1);
                    });
                  },
                  icon: const Icon(Icons.arrow_downward)),
              const SizedBox(width: 8),
              IconButton(
                  onPressed: () {
                    setState(() {
                      settings.setMaximumParallelDownloads(settings.maximumParallelDownloads + 1);
                    });
                  },
                  icon: const Icon(Icons.arrow_upward)),
            ],
          ),
        ],
      ),
    );
  }

  String convertCamelCaseToText(final String text) {
    if (text.isEmpty) return text;
    StringBuffer buffer = StringBuffer();
    buffer.write(text[0].toUpperCase());
    for (var i = 1; i < text.length; i++) {
      if (text[i] == text[i].toUpperCase()) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    return buffer.toString();
  }
}
