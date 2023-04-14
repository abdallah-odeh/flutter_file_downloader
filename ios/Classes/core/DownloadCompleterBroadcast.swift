import Foundation

class DownloadCompleterBroadcast: NSObject, URLSessionDownloadDelegate {

    let methodCallHandler: MethodCallHandlerImpl

    init(methodCallHandler: MethodCallHandlerImpl) {
        self.methodCallHandler = methodCallHandler
        super.init()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let task = methodCallHandler.getTask(downloadTask.taskIdentifier)
        guard let fileName = downloadTask.originalRequest?.url?.lastPathComponent else {
            return
        }
        let fileManager = FileManager.default
        let downloadsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let destinationURL = downloadsDirectory.appendingPathComponent(fileName)
        do {
            try fileManager.moveItem(at: location, to: destinationURL)
            task?.onDownloadCompleted(path: destinationURL.path)
            let helper = methodCallHandler.findHelper(downloadTask.taskIdentifier)
            helper?.result.success(destinationURL.path)
        } catch let error {
            let nsError = error as NSError
            let errorMessage = "\(nsError.code) - \(nsError.localizedDescription)"
            task?.onDownloadError(errorMessage: errorMessage)
            let helper = methodCallHandler.findHelper(downloadTask.taskIdentifier)
            helper?.result.error("Download file error", errorMessage, nil)
        }
        methodCallHandler.removeTask(downloadTask.taskIdentifier)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let nsError = error as NSError
            let errorMessage = "\(nsError.code) - \(nsError.localizedDescription)"
            let task = methodCallHandler.getTask(task.taskIdentifier)
            task?.onDownloadError(errorMessage: errorMessage)
            let helper = methodCallHandler.findHelper(task.taskIdentifier)
            helper?.result.error("Download file error", errorMessage, nil)
            methodCallHandler.removeTask(task.taskIdentifier)
        }
    }
}
