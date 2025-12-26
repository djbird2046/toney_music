import Cocoa
import FlutterMacOS

class SecurityScopedAccessPlugin: NSObject, FlutterPlugin {
    private var activeUrls: [String: URL] = [:]

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "security_scoped_access",
            binaryMessenger: registrar.messenger
        )
        let instance = SecurityScopedAccessPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "createBookmark":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                return result(FlutterError(code: "INVALID", message: nil, details: nil))
            }
            do {
                let url = URL(fileURLWithPath: path)
                let bookmark = try url.bookmarkData(
                    options: [.withSecurityScope],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                result(bookmark.base64EncodedString())
            } catch {
                result(FlutterError(code: "BOOKMARK_FAILED", message: error.localizedDescription, details: nil))
            }

        case "startAccess":
            guard let args = call.arguments as? [String: Any],
                  let bookmarkBase64 = args["bookmark"] as? String,
                  let data = Data(base64Encoded: bookmarkBase64) else {
                return result(FlutterError(code: "INVALID", message: nil, details: nil))
            }
            do {
                var stale = false
                var url = try URL(
                    resolvingBookmarkData: data,
                    options: [.withSecurityScope, .withoutUI],
                    relativeTo: nil,
                    bookmarkDataIsStale: &stale
                )
                var returnedBookmark: String? = nil
                if stale {
                    let refreshed = try url.bookmarkData(
                        options: [.withSecurityScope],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    returnedBookmark = refreshed.base64EncodedString()
                    url = try URL(
                        resolvingBookmarkData: refreshed,
                        options: [.withSecurityScope, .withoutUI],
                        relativeTo: nil,
                        bookmarkDataIsStale: &stale
                    )
                }
                let started = url.startAccessingSecurityScopedResource()
                if !started {
                    return result(FlutterError(code: "ACCESS_DENIED", message: "Failed to start security scope", details: nil))
                }
                let token = UUID().uuidString
                activeUrls[token] = url
                var payload: [String: Any] = [
                    "token": token,
                    "path": url.path,
                ]
                if let returnedBookmark {
                    payload["bookmark"] = returnedBookmark
                }
                result(payload)
            } catch {
                result(FlutterError(code: "RESOLVE_FAILED", message: error.localizedDescription, details: nil))
            }

        case "stopAccess":
            guard let args = call.arguments as? [String: Any],
                  let token = args["token"] as? String else {
                return result(FlutterError(code: "INVALID", message: nil, details: nil))
            }
            if let url = activeUrls.removeValue(forKey: token) {
                url.stopAccessingSecurityScopedResource()
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
