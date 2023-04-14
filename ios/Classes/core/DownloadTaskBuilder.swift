import Foundation
import UIKit

class DownloadTaskBuilder {
    private var instance: DownloadTaskBuilder
    private var url: String?
    private var name: String?
    private var callbacks: DownloadCallbacks?
    private let activity: Activity
    private var task: DownloadTask?

    init(activity: Activity) {
        self.activity = activity
        instance = self
    }

    func setUrl(url: String) -> DownloadTaskBuilder {
        instance.url = url
        return instance
    }

    func setName(name: String) -> DownloadTaskBuilder {
        instance.name = name
        return instance
    }

    func setCallbacks(callbacks: DownloadCallbacks) -> DownloadTaskBuilder {
        instance.callbacks = callbacks
        return instance
    }

    func build() -> DownloadTask {
        if task == nil {
            task = DownloadTask(activity: instance.activity, url: instance.url!, name: instance.name, callbacks: callbacks)
        }
        return getDownloadTask()
    }

    func getDownloadTask() -> DownloadTask {
        if task == nil {
            fatalError("build method is not called, you should call \"downloadTaskBuilder.build()\" first")
        }
        return task!
    }
}
