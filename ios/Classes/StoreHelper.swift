import Flutter

class StoreHelper {
    var id: String
    var call: FlutterMethodCall
    var result: FlutterResult

    init(call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.id = ""
        self.call = call
        self.result = result
    }
}
