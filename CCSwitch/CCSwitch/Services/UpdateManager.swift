import Foundation
#if canImport(Sparkle)
import Sparkle
#endif
import SwiftUI

/// Sparkle Update Manager Wrapper
@MainActor
class UpdateManager: NSObject, ObservableObject {
    static let shared = UpdateManager()

    @Published var lastUpdateCheckDate: Date?

    // Sparkle uses UserDefaults keys: SUEnableAutomaticChecks, SUAutomaticallyUpdate
    // We bind these for SwiftUI Views
    @AppStorage("SUEnableAutomaticChecks") var automaticallyChecksForUpdates = true
    @AppStorage("SUAutomaticallyUpdate") var automaticallyDownloadsAndInstallsUpdates = false

    // Dummy properties to prevent compilation errors in existing Views until they are refactored
    @Published var isChecking: Bool = false
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0
    @Published var installationStatus: String? = nil

    #if canImport(Sparkle)
    // Sparkle Controller
    private let updaterController: SPUStandardUpdaterController
    #endif

    override private init() {
        #if canImport(Sparkle)
        // Initialize Sparkle with standard user driver (UI)
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        #endif

        super.init()

        // Load last check date from Sparkle's storage
        if let lastCheckTime = UserDefaults.standard.object(forKey: "SULastCheckTime") as? Date {
            self.lastUpdateCheckDate = lastCheckTime
        }
    }

    func checkForUpdates(isManual: Bool = true) {
        #if canImport(Sparkle)
        if isManual {
            updaterController.checkForUpdates(nil)
        } else {
            updaterController.updater.checkForUpdatesInBackground()
        }
        #endif

        // Refresh last check date
        if let lastCheckTime = UserDefaults.standard.object(forKey: "SULastCheckTime") as? Date {
            self.lastUpdateCheckDate = lastCheckTime
        }
    }
}
