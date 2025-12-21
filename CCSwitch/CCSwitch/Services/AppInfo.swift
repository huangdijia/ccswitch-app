import Foundation

struct AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
    
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    static var fullVersion: String {
        "\(version) (\(build))"
    }
    
    static var name: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "CCSwitch"
    }
}
