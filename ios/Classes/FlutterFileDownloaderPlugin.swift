import Flutter
import UIKit
import Photos
import Foundation


public class FlutterFileDownloaderPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.abdallah.libs/file_downloader", binaryMessenger: registrar.messenger())
    let instance = FlutterFileDownloaderPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "checkPermission":
        result(checkStoragePermission())
        break
      case "requestPermission":
        requestStoragePermission(result: result)
        break
      case "downloadFile", "onStartDownloadingFile":
      guard let arguments = call.arguments as? [String: Any],
                    let urlString = arguments["url"] as? String,
                    let url = URL(string: urlString) else {
                  result(FlutterError(code: "invalid_argument",
                                       message: "Invalid argument",
                                       details: nil))
                  return
              }
              downloadFileFromURL(url: url)
        requestStoragePermission(result: result)
        break
      default:
          result(FlutterMethodNotImplemented)
      }
  }

func checkStoragePermission() -> Bool {
    let status = PHPhotoLibrary.authorizationStatus()
    return status == .authorized
}

    func requestStoragePermission(result: @escaping FlutterResult) {
        PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    result(true)
                case .denied, .restricted:
                    result(false)
                case .notDetermined:
                    result(FlutterError(code: "PERMISSION_NOT_GRANTED", message: "Permission not granted", details: nil))
                @unknown default:
                    result(false)
                }
            }
    }


func downloadFileFromURL(url: URL) {
    // Create destination URL in downloads directory
    guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
    let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)

    // Create URL request
    let urlRequest = URLRequest(url: url)

    // Create URLSession task to download file
    let task = URLSession.shared.downloadTask(with: urlRequest) { (tempLocalUrl, response, error) in
        if let error = error {
            print("Error downloading file: \(error.localizedDescription)")
            return
        }

        guard let tempLocalUrl = tempLocalUrl else { return }

        do {
            // Copy downloaded file to destination URL
            try FileManager.default.copyItem(at: tempLocalUrl, to: destinationUrl)
            print("File downloaded successfully to: \(destinationUrl.absoluteString)")
        } catch (let writeError) {
            print("Error writing file to disk: \(writeError.localizedDescription)")
        }
    }

    // Start the download task
    task.resume()
}

}
