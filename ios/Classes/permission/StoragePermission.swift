enum StoragePermission {
    case denied
    case deniedForever
    case always

    func toInt() -> Int {
        switch self {
        case .denied:
            return 0
        case .deniedForever:
            return 1
        case .always:
            return 2
        }
    }
}
