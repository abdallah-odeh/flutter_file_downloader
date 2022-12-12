import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

bool replaceFilesOldVersions = false;

class _SettingsScreenState extends State<SettingsScreen> {

  bool logEnabled = FileDownloader().isLogEnabled;
  int parallelTasks = FileDownloader().maximumParallelDownloads;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enable logs', style: Theme.of(context).textTheme.headline6,),
          Row(
            children: [
              Expanded(
                child: Text(logEnabled ? 'Enabled' : 'Disabled', style: Theme.of(context).textTheme.subtitle1),
              ),
              const SizedBox(width: 16),
              Switch(value: logEnabled, onChanged: (value){
                setState(() => logEnabled = value);
                FileDownloader.setLogEnabled(logEnabled);
              })
            ],
          ),


          const SizedBox(height: 16),
          const Divider(
              color: Colors.grey,
              height: 1
          ),
          const SizedBox(height: 32),

          Text('Replace any file if already exists?', style: Theme.of(context).textTheme.headline6,),
          Row(
            children: [
              Expanded(
                child: Text(replaceFilesOldVersions ? 'Enabled' : 'Disabled', style: Theme.of(context).textTheme.subtitle1),
              ),
              const SizedBox(width: 16),
              Switch(value: replaceFilesOldVersions, onChanged: (value){
                setState(() => replaceFilesOldVersions = value);
              })
            ],
          ),

          const SizedBox(height: 16),
          const Divider(
            color: Colors.grey,
            height: 1
          ),
          const SizedBox(height: 32),

          Text('Maximum parallel downloads', style: Theme.of(context).textTheme.headline6,),
          Row(
            children: [
              Expanded(
                child: Text(parallelTasks.toString(), style: Theme.of(context).textTheme.subtitle1),
              ),
              const SizedBox(width: 16),
              IconButton(onPressed: (){
                FileDownloader.setMaximumParallelDownloads(parallelTasks - 1);
                setState(() => parallelTasks = FileDownloader().maximumParallelDownloads);
              }, icon: Icon(Icons.arrow_downward)),
              const SizedBox(width: 8),
              IconButton(onPressed: () {
                FileDownloader.setMaximumParallelDownloads(parallelTasks + 1);
                setState(() =>
                parallelTasks = FileDownloader().maximumParallelDownloads);
              }, icon: Icon(Icons.arrow_upward)),
            ],
          ),
        ],
      ),
    );
  }
}
