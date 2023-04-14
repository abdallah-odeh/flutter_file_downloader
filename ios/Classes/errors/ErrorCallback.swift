import Foundation

protocol ErrorCallback {
    func onError(_ errorCode: ErrorCodes)
}

enum ErrorCodes: Error {
    case networkError
    case permissionDenied
}

