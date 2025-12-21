import Foundation

struct AppInfo {
    /// 获取版本号 (e.g., "1.0.0")
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
    
    /// 获取构建号 (e.g., "1")
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }
    
    /// 获取完整版本号 (e.g., "1.0.0 (1)")
    static var fullVersion: String {
        "\(version) (\(build))"
    }
    
    /// 获取应用显示名称
    static var name: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "CCSwitch"
    }
}