enum ErrorCodes {
    case activityMissing
    case permissionDefinitionsNotFound
    case permissionDenied
    case permissionRequestInProgress

    func toString() -> String {
        switch self {
        case .activityMissing:
            return "ACTIVITY_MISSING"
        case .permissionDefinitionsNotFound:
            return "PERMISSION_DEFINITIONS_NOT_FOUND"
        case .permissionDenied:
            return "PERMISSION_DENIED"
        case .permissionRequestInProgress:
            return "PERMISSION_REQUEST_IN_PROGRESS"
        }
    }

    func toDescription() -> String {
        switch self {
        case .activityMissing:
            return "Activity is missing. This might happen when running a certain function from the background that requires a UI element (e.g. requesting permissions)."
        case .permissionDefinitionsNotFound:
            return "No storage permission is defined in the manifest. Make sure that WRITE_EXTERNAL_STORAGE is defined in the manifest."
        case .permissionDenied:
            return "User denied permissions to access the device's files."
        case .permissionRequestInProgress:
            return "Already listening for storage updates. If you want to restart listening please cancel other subscriptions first"
        }
    }
}
