#if canImport(Flutter)
import Flutter
#elseif canImport(FlutterMacOS)
import FlutterMacOS
#endif

public class CleverTapNativeDisplayPlugin: NSObject, FlutterPlugin {

    // Set by the host app after initialising CleverTap Core SDK.
    public var bridge: NativeDisplayPluginBridge?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.clevertap.flutter.nativedisplay",
            binaryMessenger: registrar.messenger()
        )
        let instance = CleverTapNativeDisplayPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments missing", details: nil))
            return
        }

        switch call.method {
        case "fetchDisplayUnit":
            guard let unitId = args["unitId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "unitId is required", details: nil))
                return
            }
            result(bridge?.fetchDisplayUnit(unitId: unitId))

        case "pushViewedEvent":
            if let unitId = args["unitId"] as? String {
                let additionalProperties = args["additionalProperties"] as? [String: Any]
                bridge?.pushViewedEvent(unitId: unitId, additionalProperties: additionalProperties)
            }
            result(nil)

        case "pushClickedEvent":
            if let unitId = args["unitId"] as? String {
                let elementId = args["elementId"] as? String
                let additionalProperties = args["additionalProperties"] as? [String: Any]
                bridge?.pushClickedEvent(
                    unitId: unitId,
                    elementId: elementId,
                    additionalProperties: additionalProperties
                )
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

public protocol NativeDisplayPluginBridge {
    // Return display unit JSON string for the given unitId, or nil if not found.
    func fetchDisplayUnit(unitId: String) -> String?

    // Report viewed event to CleverTap Core SDK.
    // `additionalProperties` carries the ND SDK version stamp (nd_lib_v_*) to
    // forward to the ND SDK's viewed-with-extras path as additionalProperties.
    func pushViewedEvent(unitId: String, additionalProperties: [String: Any]?)

    // Report clicked event to CleverTap Core SDK.
    // `additionalProperties` carries the clicked action's attribution extras
    // (action_type, custom KVs, and BE-injected wzrk_* fields) to forward to the
    // ND SDK's element-clicked path as Core SDK additionalProperties.
    func pushClickedEvent(unitId: String, elementId: String?, additionalProperties: [String: Any]?)
}
