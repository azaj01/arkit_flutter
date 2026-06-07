import Flutter

public class ArkitPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        SwiftArkitPlugin.register(with: registrar)
        VideoArkitPlugin.register(with: registrar)
    }
}
