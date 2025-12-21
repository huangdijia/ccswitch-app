import Foundation
import UserNotifications

/// Protocol for notification operations
/// This abstraction allows for different notification mechanisms and improves testability
protocol NotificationService {
    /// Send a notification to the user
    /// - Parameters:
    ///   - title: Notification title
    ///   - message: Notification message body
    func notify(title: String, message: String)
    
    /// Request notification permissions from the user
    func requestPermission()
}

/// Default implementation using UserNotifications framework
class UserNotificationService: NotificationService {
    private let notificationCenter: UNUserNotificationCenter
    private let settings: SettingsRepository
    
    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        settings: SettingsRepository = UserDefaultsSettingsRepository()
    ) {
        self.notificationCenter = notificationCenter
        self.settings = settings
    }
    
    func notify(title: String, message: String) {
        // Check if notifications are enabled
        guard settings.getBool(for: .showSwitchNotification) else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                Logger.shared.error("Failed to show notification: \(error)")
            }
        }
    }
    
    func requestPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                Logger.shared.error("Failed to request notification permission: \(error)")
            } else if granted {
                Logger.shared.info("Notification permission granted")
            }
        }
    }
}

/// Mock implementation for testing
class MockNotificationService: NotificationService {
    var lastNotification: (title: String, message: String)?
    var permissionRequested = false
    
    func notify(title: String, message: String) {
        lastNotification = (title, message)
    }
    
    func requestPermission() {
        permissionRequested = true
    }
}
