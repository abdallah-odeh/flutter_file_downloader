import UIKit
import Foundation
import Photos

enum StoragePermission {
    case always
    case denied
    case deniedForever
}

enum ErrorCodes: String {
    case activityMissing = "Activity Missing"
    case permissionDefinitionsNotFound = "Permission Definitions Not Found"
}

typealias PermissionResultCallback = (StoragePermission) -> Void
typealias ErrorCallback = (ErrorCodes) -> Void

class PermissionManager {

    func checkPermissionStatus() -> StoragePermission {
        let status = PHPhotoLibrary.authorizationStatus()
switch status {
            case .authorized:
                return StoragePermission.always
            case .denied, .restricted:
                // Permission denied or restricted
                // Display an alert explaining the situation
                let alert = UIAlertController(title: "Permission Required", message: "Storage permission is required to use this app.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                return checkPermissionStatus()
            case .notDetermined:
                // Permission not determined yet
                // Do nothing, user has not been asked for permission yet
                break
            @unknown default:
                // Handle any future cases if necessary
                break
            }
    }

  func requestStoragePermission(){
    PHPhotoLibrary.requestAuthorization {
        (status) in checkPermissionStatus()
    }
  }

}