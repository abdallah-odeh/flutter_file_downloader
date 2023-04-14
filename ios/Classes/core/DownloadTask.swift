import UIKit

class DownloadTask {
    let activity: UIViewController
    let url: String
    let name: String?
    let callbacks: DownloadCallbacks?
    private var isDownloading = false

    init(activity: UIViewController, url: String, name: String?, callbacks: DownloadCallbacks?) {
        self.callbacks = callbacks
        self.activity = activity
        self.url = url
        self.name = name
    }

    convenience init(activity: UIViewController, url: String, name: String?) {
        self.init(activity: activity, url: url, name: name, callbacks: nil)
    }

    func startDownloading() {
        isDownloading = true
        let request = URLRequest(url: URL(string: url)!)

        let directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let filePath = directoryURL.appendingPathComponent(getDownloadedFileName()).path

        let task = URLSession.shared.downloadTask(with: request) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                print("Download failed: \(error!.localizedDescription)")
                return
            }

            do {
                try FileManager.default.moveItem(atPath: localURL.path, toPath: filePath)
                print("Download successful: \(filePath)")
            } catch {
                print("Error moving file: \(error)")
            }
        }
        task.resume()
        if let callbacks = callbacks {
            callbacks.onIDReceived(task.taskIdentifier)
            trackDownload(task: task)
        }
    }

    private func trackDownload(task: URLSessionDownloadTask) {
        let uiThreadHandler = DispatchQueue.main
        DispatchQueue.global(qos: .background).async {
            var lastProgress = -1.0

            while self.isDownloading {
                let bytes_downloaded = task.countOfBytesReceived
                let bytes_total = task.countOfBytesExpectedToReceive

                if task.state == .completed {
                    self.isDownloading = false
                }

                let dl_progress = Double(bytes_downloaded * 100) / Double(bytes_total)
                if lastProgress != dl_progress {
                    uiThreadHandler.async {
                        self.callbacks?.onProgress(dl_progress)
                        self.callbacks?.onProgress(self.getDownloadedFileName(), progress: dl_progress)
                    }
                    lastProgress = dl_progress
                }
            }
        }
    }

    private func getName() -> String {
        if let name = name, !name.isEmpty {
            return name
        }
        let segments = url.split(separator: "/")
        return String(segments.last!)
    }

    private func getExtension() -> String {
        var toCheck = name
        if let toCheck = toCheck, !toCheck.isEmpty {
            if !toCheck.contains(".") {
                let segments = url.split(separator: "/")
                toCheck = String(segments.last!)
            }
        } else {
            toCheck = getName()
        }
        return String(toCheck!.suffix(from: toCheck!.lastIndex(of: ".")!))
    }

    private func getDownloadedFileName() -> String {
        if name == nil || name!.isEmpty {
            return getName()
        }
        var fileName = getName()
        let extensionString = getExtension()
        if fileName.contains(".") {
            fileName = String(fileName.prefix(upTo: fileName.lastIndex(of: ".")))
        }
        return "\(fileName).\(extensionString)"
    }
}
