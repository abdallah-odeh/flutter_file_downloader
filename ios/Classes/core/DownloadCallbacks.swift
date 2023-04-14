import Foundation

class DownloadCallbacks {
    var id: Int64 = 0

    func onIDReceived(_ id: Int64) {
        self.id = id
    }

    func onProgress(_ progress: Double) {}

    func onProgress(_ name: String, _ progress: Double) {}

    func onDownloadCompleted(_ path: String) {}

    func onDownloadError(_ errorMessage: String) {}
}
