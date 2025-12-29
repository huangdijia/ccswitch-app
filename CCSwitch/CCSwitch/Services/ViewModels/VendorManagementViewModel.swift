import Foundation
import Combine

// MARK: - Vendor Management ViewModel Protocol

/// Protocol for vendor management view model
/// This abstraction allows for different implementations and improves testability
protocol VendorManagementViewModelProtocol: ObservableObject {
    // MARK: - Published Properties
    var vendors: [Vendor] { get }
    var currentVendorId: String { get }
    var favoriteIds: Set<String> { get }
    var presetIds: Set<String> { get }
    var searchText: String { get set }

    // MARK: - Computed Properties
    var filteredVendors: [Vendor] { get }
    var favoriteVendors: [Vendor] { get }
    var otherVendors: [Vendor] { get }

    // MARK: - Vendor Operations
    func loadData() async
    func addVendor(_ vendor: Vendor) throws
    func updateVendor(_ vendor: Vendor) throws
    func removeVendor(with id: String) throws
    func duplicateVendor(_ vendor: Vendor) throws

    // MARK: - Vendor Selection
    func switchToVendor(with id: String) async throws

    // MARK: - Favorite Management
    func isFavorite(_ id: String) -> Bool
    func toggleFavorite(_ id: String)

    // MARK: - Preset Management
    func isPreset(_ id: String) -> Bool

    // MARK: - Vendor Validation
    func validateVendorName(_ name: String) -> Bool
    func validateBaseURL(_ url: String) -> Bool
    func validateTimeout(_ timeout: String) -> Bool
}

// MARK: - Default Implementation

/// Default implementation of VendorManagementViewModel
class DefaultVendorManagementViewModel: VendorManagementViewModelProtocol {
    // MARK: - Published Properties
    @Published var vendors: [Vendor] = []
    @Published var currentVendorId: String = ""
    @Published var favoriteIds: Set<String> = []
    @Published var presetIds: Set<String> = []
    @Published var searchText: String = ""

    // MARK: - Dependencies
    private let configManager: ConfigManager
    private let notificationService: NotificationService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var filteredVendors: [Vendor] {
        if searchText.isEmpty {
            return vendors
        } else {
            return vendors.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var favoriteVendors: [Vendor] {
        filteredVendors.filter { favoriteIds.contains($0.id) }
    }

    var otherVendors: [Vendor] {
        filteredVendors.filter { !favoriteIds.contains($0.id) }
    }

    // MARK: - Initialization
    init(
        configManager: ConfigManager = .shared,
        notificationService: NotificationService = ServiceContainer.shared.notificationService
    ) {
        self.configManager = configManager
        self.notificationService = notificationService

        // Subscribe to configuration changes
        NotificationCenter.default.publisher(for: .configDidChange)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading
    func loadData() async {
        await MainActor.run {
            vendors = configManager.allVendors
            currentVendorId = configManager.currentVendor?.id ?? ""
            favoriteIds = configManager.favoriteVendorIds
            presetIds = configManager.presetVendorIds
        }
    }

    // MARK: - Vendor Operations
    func addVendor(_ vendor: Vendor) throws {
        try configManager.addVendor(vendor)
        Logger.shared.info("Added vendor: \(vendor.id)")

        notificationService.notify(
            title: NSLocalizedString("vendor_added_success", comment: ""),
            message: String(format: NSLocalizedString("vendor_added_message", comment: ""), vendor.displayName)
        )
    }

    func updateVendor(_ vendor: Vendor) throws {
        try configManager.updateVendor(vendor)
        Logger.shared.info("Updated vendor: \(vendor.id)")

        notificationService.notify(
            title: NSLocalizedString("vendor_updated_success", comment: ""),
            message: String(format: NSLocalizedString("vendor_updated_message", comment: ""), vendor.displayName)
        )
    }

    func removeVendor(with id: String) throws {
        // Check if it's the current vendor
        if id == currentVendorId {
            throw VendorManagementError.cannotRemoveCurrentVendor
        }

        // Check if it's the last vendor
        if vendors.count == 1 {
            throw VendorManagementError.cannotRemoveLastVendor
        }

        try configManager.removeVendor(with: id)
        Logger.shared.info("Removed vendor: \(id)")

        notificationService.notify(
            title: NSLocalizedString("vendor_deleted_success", comment: ""),
            message: NSLocalizedString("vendor_deleted_message", comment: "")
        )
    }

    func duplicateVendor(_ vendor: Vendor) throws {
        let newId = UUID().uuidString.prefix(8).lowercased()
        let suffix = NSLocalizedString(LocalizationKey.copySuffix, comment: "")
        let newVendor = Vendor(
            id: String(newId),
            name: "\(vendor.displayName)\(suffix)",
            env: vendor.env
        )
        try addVendor(newVendor)
        Logger.shared.info("Duplicated vendor: \(vendor.id) -> \(newId)")
    }

    // MARK: - Vendor Selection
    func switchToVendor(with id: String) async throws {
        try configManager.switchToVendor(with: id)
        await loadData()
    }

    // MARK: - Favorite Management
    func isFavorite(_ id: String) -> Bool {
        return favoriteIds.contains(id)
    }

    func toggleFavorite(_ id: String) {
        configManager.toggleFavorite(id)
        let wasFavorite = favoriteIds.contains(id)
        let msgKey = wasFavorite ? "removed_from_favorites_msg" : "added_to_favorites_msg"

        notificationService.notify(
            title: "",
            message: NSLocalizedString(msgKey, comment: "")
        )
    }

    // MARK: - Preset Management
    func isPreset(_ id: String) -> Bool {
        return configManager.isPreset(id)
    }

    // MARK: - Vendor Validation
    func validateVendorName(_ name: String) -> Bool {
        return !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func validateBaseURL(_ url: String) -> Bool {
        let trimmed = url.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return true // Empty is valid (optional field)
        }
        return trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://")
    }

    func validateTimeout(_ timeout: String) -> Bool {
        let trimmed = timeout.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return true // Empty is valid (optional field)
        }
        guard let value = Int(trimmed) else {
            return false
        }
        return value >= 1000 && value <= 300000
    }
}

// MARK: - Vendor Management Errors

enum VendorManagementError: LocalizedError {
    case cannotRemoveCurrentVendor
    case cannotRemoveLastVendor
    case invalidVendorName
    case invalidBaseURL
    case invalidTimeout

    var errorDescription: String? {
        switch self {
        case .cannotRemoveCurrentVendor:
            return NSLocalizedString("error_cannot_remove_current_vendor", comment: "")
        case .cannotRemoveLastVendor:
            return NSLocalizedString("error_cannot_remove_last_vendor", comment: "")
        case .invalidVendorName:
            return NSLocalizedString("error_invalid_vendor_name", comment: "")
        case .invalidBaseURL:
            return NSLocalizedString("error_invalid_base_url", comment: "")
        case .invalidTimeout:
            return NSLocalizedString("error_invalid_timeout", comment: "")
        }
    }
}
