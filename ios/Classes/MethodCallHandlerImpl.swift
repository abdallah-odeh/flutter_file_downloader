import Flutter

class MethodCallHandlerImpl: NSObject, FlutterPlugin {

    private static let channelName = "com.abdallah.libs/file_downloader"

    private let permissionManager: PermissionManager

    private var context: FlutterPluginBinding?
    private var lastURL: String?
    private var lastName: String?
    private var tasks: [Int64: DownloadCallbacks] = [:]
    private var stored: [String: StoreHelper] = [:]

    init(permissionManager: PermissionManager) {
        self.permissionManager = permissionManager
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MethodCallHandlerImpl(permissionManager: PermissionManager())
        instance.startListening(registrar: registrar)
    }

    private func startListening(registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: MethodCallHandlerImpl.channelName, binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(self, channel: channel)
        self.context = registrar
    }

    private func stopListening() {
        guard let context = context else { return }
        let channel = FlutterMethodChannel(name: MethodCallHandlerImpl.channelName, binaryMessenger: context.binaryMessenger)
        channel.setMethodCallHandler(nil)
        self.context = nil
    }

    private func findHelper(id: Int64) -> StoreHelper? {
        for (_, helper) in stored {
            if helper.id == id {
                return helper
            }
        }
        return nil
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let helper = StoreHelper(call: call, result: result)
        stored[call.argument("key") as! String] = helper

        switch call.method {
        case "checkPermission":
            onCheckPermission(result: result)
        case "requestPermission":
            onRequestPermission(helper: helper, sendResult: true)
        case "onStartDownloadingFile", "downloadFile":
            onStartDownloadingFile(helper: helper)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func onCheckPermission(result: FlutterResult) {
        do {
            let permission = try permissionManager.checkPermissionStatus()
            result(permission.rawValue)
        } catch {
            let errorCode = ErrorCodes.permissionDefinitionsNotFound
            result(FlutterError(code: errorCode.rawValue, message: errorCode.toDescription(), details: nil))
        }
    }

    private func onRequestPermission(helper: StoreHelper, sendResult: Bool) {
        do {
            try permissionManager.requestPermission(
                onResult: { permission in
                    if sendResult {
                        helper.result(permission.rawValue)
                        stored.removeValue(forKey: helper.call.argument("key") as! String)
                    } else {
                        if permission != .always {
                            let errorCode = ErrorCodes.permissionDenied
                            helper.result(FlutterError(code: errorCode.rawValue, message: errorCode.toDescription(), details: nil))
                            stored.removeValue(forKey: helper.call.argument("key") as! String)
                        } else {
                            self.handle(helper.call, result: helper.result)
                        }
                    }
                },
                onError: { errorCode in
                    helper.result(FlutterError(code: errorCode.rawValue, message: errorCode.toDescription(), details: nil))
                }
            )
        } catch {
            let errorCode = ErrorCodes.permissionDefinitionsNotFound
            helper.result(FlutterError(code: errorCode.rawValue, message: errorCode.toDescription(), details: nil))
        }
    }
private func onStartDownloadingFile(_ helper: StoreHelper) {
    do {
        if !permissionManager.hasPermission(context) {
            onRequestPermission(helper, false)
            return
        }
    } catch PermissionUndefinedException {
        helper.result.error(
            ErrorCodes.permissionDefinitionsNotFound.rawValue,
            ErrorCodes.permissionDefinitionsNotFound.toDescription(),
            nil)
        return
    }

    guard let args = helper.call.arguments as? [String: Any] else { return }
    lastURL = args["url"] as? String
    lastName = args["name"] as? String

    let downloadCallbacks = DownloadCallbacks()
    downloadCallbacks.onIDReceived = { id in
        tasks[id] = downloadCallbacks

        guard let onIDReceived = args["onidreceived"] as? String else { return }
        var argsDict = [String: Any]()
        argsDict["id"] = id
        argsDict["url"] = args["url"]
        argsDict["key"] = args["key"]
        stored[args["key"] as? String ?? ""]?.id = "\(id)"
        channel.invokeMethod("onIDReceived", arguments: argsDict)
    }
    downloadCallbacks.onProgress = { progress in
        guard let onProgress = args["onprogress"] as? String else { return }
        var argsDict = [String: Any]()
        argsDict["id"] = id
        argsDict["progress"] = progress
        argsDict["key"] = args["key"]
        channel.invokeMethod("onProgress", arguments: argsDict)
    }
    downloadCallbacks.onProgressWithName = { name, progress in
        guard let onProgressWithName = args["onprogress_named"] as? String else { return }
        var argsDict = [String: Any]()
        argsDict["id"] = id
        argsDict["name"] = name
        argsDict["progress"] = progress
        argsDict["key"] = args["key"]
        channel.invokeMethod("onProgress", arguments: argsDict)
    }
    downloadCallbacks.onDownloadCompleted = { path in
        guard let onDownloadCompleted = args["ondownloadcompleted"] as? String else { return }
        var argsDict = [String: Any]()
        argsDict["id"] = id
        argsDict["path"] = path
        argsDict["key"] = args["key"]
        channel.invokeMethod("onDownloadCompleted", arguments: argsDict)
    }
    downloadCallbacks.onDownloadError = { errorMessage in
        guard let onDownloadError = args["ondownloaderror"] as? String else { return }
        var argsDict = [String: Any]()
        argsDict["id"] = id
        argsDict["error"] = errorMessage
        argsDict["key"] = args["key"]
        channel.invokeMethod("onDownloadError", arguments: argsDict)
    }

    let builder = DownloadTaskBuilder(activity)
    builder.setUrl(lastURL)
    builder.setName(lastName)
    builder.setCallbacks(downloadCallbacks)
    builder.build().startDownloading()
}

func removeTask(_ id: Int64) {
    tasks.removeValue(forKey: id)
}

func getTask(_ id: Int64) -> DownloadCallbacks? {
    return tasks[id]
}
}