import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

class MultipleDownloads extends StatefulWidget {
  const MultipleDownloads({Key? key}) : super(key: key);

  @override
  State<MultipleDownloads> createState() => _MultipleDownloadsState();
}

class _MultipleDownloadsState extends State<MultipleDownloads> {
  final controller = TextEditingController();
  final List<_DownloadTask> tasks = [];
  bool isParallel = true, loading = false;

  final urls = <String>[
    'https://helpx.adobe.com/content/dam/help/en/photoshop/using/convert-color-image-black-white/jcr_content/main-pars/before_and_after/image-before/Landscape-Color.jpg',
    'https://icatcare.org/app/uploads/2018/07/Helping-your-new-cat-or-kitten-settle-in-1.png',
    'https://www.veterinarypracticenews.com/wp-content/uploads/2019/04/bigstock-225181321.jpg',
    'https://cdn.mos.cms.futurecdn.net/vChK6pTy3vN3KbYZ7UU7k3-320-80.jpg',
    'https://www.prestigeanimalhospital.com/sites/default/files/interesting-cat-facts.jpg',
    'https://i.pinimg.com/736x/d4/9b/e9/d49be9b1afcc341a5d14fa3af5e11891--funny-smiles-happy-faces.jpg',
    'https://www.severnedgevets.co.uk/sites/default/files/guides/kitten.png',
    'https://icatcare.org/app/uploads/2019/09/The-Kitten-Checklist-1.png',
    'https://www.thehappycatsite.com/wp-content/uploads/2018/08/how-to-tell-how-old-a-kitten-is-long.jpg',
    'https://i.pinimg.com/originals/fb/f6/d6/fbf6d69bb0b3507debc73b5cbe1d4bda.jpg',
    'https://wallpapermemory.com/uploads/206/cat-wallpaper-hd-1600x900-426754.jpg',
    'https://fansided.com/files/2015/10/cat.jpg',
    'https://i.pinimg.com/564x/b9/17/64/b91764a4a240c340bdd0f3ba452f384a.jpg',
    'https://www.banningvet.com/files/banning_vet/puppies-kittens.jpg',
    'https://cdn.onemars.net/sites/perfect-fit_uk_Z61CM_JAs8/image/editor/fotolia_159510848_subscription_yearly_m_1613832396390.jpg',
    'https://i.pinimg.com/originals/0d/ec/ab/0decabaffcd9c57bcc9327fed1c69a1f.jpg',
    'https://i.pinimg.com/originals/aa/02/78/aa02780bbc7e6c5e2d52d9b0e919fbf6.jpg',
    'https://i.pinimg.com/474x/ab/91/ee/ab91eef95a4b974f3dcb32c497802f08.jpg',
    'https://preview.redd.it/4s4r609fw5r61.jpg?auto=webp&s=d1142e9abadfb8df68cbb31850cdd1e93ea6c24a',
    'https://i.pinimg.com/originals/79/9a/68/799a6842c8d0303057231d10ebf09a9c.jpg',
    'https://images.fineartamerica.com/images/artworkimages/mediumlarge/1/little-cute-kitten-serhii-kucher.jpg',
    'https://image.shutterstock.com/image-photo/cute-persian-kitten-walking-on-260nw-767854171.jpg',
    'https://bpah.net/wp-content/uploads/2019/10/Nutrition-for-puppies-and-kittens_Kittens_iSt927401846.jpg',
    'https://wallsdesk.com/wp-content/uploads/2018/03/Cat-High-Quality-Wallpapers.jpg',
    'http://images4.fanpop.com/image/photos/16000000/Cute-Kittens-kittens-16094703-1280-800.jpg',
    'https://c4.wallpaperflare.com/wallpaper/701/216/855/cat-4k-high-resolution-image-wallpaper-preview.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parallel download',
            style: Theme.of(context).textTheme.headline6,
          ),
          Row(
            children: [
              Expanded(
                child: Text(isParallel ? 'Enabled' : 'Disabled',
                    style: Theme.of(context).textTheme.subtitle1),
              ),
              const SizedBox(width: 16),
              Switch(
                  value: isParallel,
                  onChanged: (value) {
                    setState(() => isParallel = value);
                  })
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration:
                      const InputDecoration(label: Text('Url to download')),
                ),
              ),
              GestureDetector(
                onTap: appendRandom,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: const Icon(
                    Icons.shuffle,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: submit,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (loading) ...const [
            SizedBox(height: 16),
            LinearProgressIndicator(),
          ],
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.grey, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                      onPressed: () async {
                        setState(() => loading = true);
                        final files = await FileDownloader.downloadFiles(
                            urls: tasks.map((e) => e.url).toList(),
                            isParallel: isParallel,
                            onAllDownloaded: () =>
                                setState(() => loading = false));
                        for (int i = 0; i < files.length; i++) {
                          tasks[i].path = files[i]?.path;
                          tasks[i].finishedDownloading = true;
                        }
                        setState(() {});
                      },
                      child: const Text('Download')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                      onPressed: () async {
                        setState(() => tasks.clear());
                      },
                      child: const Text('Clear')),
                ),
              ],
            ),
          ],
          for (final task in tasks.reversed) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.grey, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8.0),
                if (task.finishedDownloading) ...[
                  if (task.path?.isEmpty ?? true)
                    const Icon(Icons.close, color: Colors.red)
                  else
                    const Icon(Icons.check, color: Colors.green),
                  const SizedBox(width: 8.0),
                ],
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    controller.text = task.url;
                    setState(() => tasks.remove(task));
                  },
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() => tasks.remove(task));
                  },
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  void appendRandom() {
    setState(
        () => tasks.add(_DownloadTask(url: urls[tasks.length % urls.length])));
  }

  void submit() {
    if (controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter download url first'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() {
      tasks.add(_DownloadTask(url: controller.text));
      controller.clear();
    });
  }
}

class _DownloadTask {
  final String url;
  String? path, error;
  bool finishedDownloading;

  _DownloadTask({required this.url}) : finishedDownloading = false;
}
