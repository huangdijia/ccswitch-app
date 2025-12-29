import SwiftUI

struct VendorManagementView: View {
    // MARK: - ViewModel Injection
    @StateObject private var viewModel: DefaultVendorManagementViewModel

    // MARK: - Local State
    @State private var selectedVendorId: String?

    // Navigation Guard & Alert State
    @State private var isDetailDirty: Bool = false
    @State private var pendingVendorId: String? = nil

    enum ActiveAlert: Identifiable {
        case deleteConfirmation(Vendor)
        case unsavedChanges(vendorName: String)
        case error(String)

        var id: String {
            switch self {
            case .deleteConfirmation(let v): return "del-\(v.id)"
            case .unsavedChanges(let name): return "unsaved-\(name)"
            case .error(let msg): return "err-\(msg.hashValue)"
            }
        }
    }
    @State private var activeAlert: ActiveAlert?

    var filteredVendors: [Vendor] {
        viewModel.filteredVendors
    }

    var favoriteVendors: [Vendor] {
        viewModel.favoriteVendors
    }

    var otherVendors: [Vendor] {
        viewModel.otherVendors
    }

    // MARK: - Initialization
    init(
        viewModel: DefaultVendorManagementViewModel = DefaultVendorManagementViewModel()
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebarView
            Divider()
            detailView
        }
        .frame(minHeight: 450)
        .onAppear {
            Task {
                await viewModel.loadData()
                if selectedVendorId == nil, let first = viewModel.vendors.first {
                    selectedVendorId = first.id
                }
            }
        }
        .alert(item: $activeAlert) { alertType in
            alert(for: alertType)
        }
    }

    // MARK: - Sidebar View

    private var sidebarView: some View {
        VStack(spacing: 0) {
            searchBar
            vendorList
            bottomToolbar
        }
        .frame(width: 200)
        .background(.thinMaterial)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(LocalizedStringKey(LocalizationKey.searchVendors), text: $viewModel.searchText)
                .textFieldStyle(.plain)
        }
        .padding(8)
        .background(Color.clear)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor).opacity(0.5)),
            alignment: .bottom
        )
    }

    private var vendorList: some View {
        let selectionBinding = Binding<String?>(
            get: { selectedVendorId },
            set: { attemptSelectionChange(to: $0) }
        )

        return List(selection: selectionBinding) {
            favoritesSection
            allVendorsSection
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .frame(minWidth: 200)
    }

    private var favoritesSection: some View {
        Group {
            if !favoriteVendors.isEmpty {
                Section(LocalizedStringKey(LocalizationKey.favorites)) {
                    ForEach(favoriteVendors) { vendor in
                        vendorRow(for: vendor)
                    }
                }
            }
        }
    }

    private var allVendorsSection: some View {
        Section(LocalizedStringKey(LocalizationKey.allVendors)) {
            ForEach(otherVendors) { vendor in
                vendorRow(for: vendor)
            }
        }
    }

    private func vendorRow(for vendor: Vendor) -> some View {
        VendorRowView(
            vendor: vendor,
            isActive: vendor.id == viewModel.currentVendorId,
            isFavorite: viewModel.isFavorite(vendor.id),
            isPreset: viewModel.isPreset(vendor.id),
            onToggleFavorite: {
                viewModel.toggleFavorite(vendor.id)
            }
        )
        .tag(vendor.id)
        .contextMenu { vendorContextMenu(vendor) }
    }

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            addVendorButton
            Divider().frame(height: 16)
            deleteVendorButton
            Spacer()
        }
        .background(Color.clear)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor).opacity(0.3)),
            alignment: .top
        )
    }

    private var addVendorButton: some View {
        Button(action: addNewVendor) {
            Image(systemName: "plus")
                .contentShape(Rectangle())
                .frame(width: 30, height: 28)
        }
        .buttonStyle(.plain)
        .help(LocalizationKey.localized(LocalizationKey.addNewVendor))
    }

    private var deleteVendorButton: some View {
        Button(action: {
            if let id = selectedVendorId,
               let v = viewModel.vendors.first(where: { $0.id == id }) {
                activeAlert = .deleteConfirmation(v)
            }
        }) {
            Image(systemName: "minus")
                .contentShape(Rectangle())
                .frame(width: 30, height: 28)
        }
        .buttonStyle(.plain)
        .disabled(selectedVendorId == nil || selectedVendorId == viewModel.currentVendorId)
        .help(LocalizationKey.localized(LocalizationKey.deleteVendor))
    }

    // MARK: - Detail View

    private var detailView: some View {
        ZStack {
            if let selectedId = selectedVendorId,
               let vendor = viewModel.vendors.first(where: { $0.id == selectedId }) {
                VendorDetailView(
                    vendor: vendor,
                    isActive: vendor.id == viewModel.currentVendorId,
                    isDirtyBinding: $isDetailDirty,
                    onSave: handleSave,
                    onSwitchVendor: { id in
                        Task {
                            do {
                                try await viewModel.switchToVendor(with: id)
                            } catch {
                                activeAlert = .error(error.localizedDescription)
                            }
                        }
                    }
                )
                .id(selectedId)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .background(Color(NSColor.windowBackgroundColor))
            } else {
                emptyStateView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(LocalizedStringKey(LocalizationKey.noVendorSelected))
                .font(.title3)
                .foregroundColor(.secondary)
            Text(LocalizedStringKey(LocalizationKey.noVendorSelectedDesc))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Alert

    private func alert(for alertType: ActiveAlert) -> Alert {
        switch alertType {
        case .deleteConfirmation(let vendor):
            return Alert(
                title: Text(LocalizationKey.deleteVendor),
                message: Text(String(format: LocalizationKey.localized(LocalizationKey.deleteVendorConfirmation), vendor.displayName)),
                primaryButton: .destructive(Text(LocalizationKey.delete)) { deleteVendor(vendor) },
                secondaryButton: .cancel()
            )
        case .unsavedChanges(let vendorName):
            return Alert(
                title: Text(LocalizationKey.unsavedChanges),
                message: Text(String(format: LocalizationKey.localized(LocalizationKey.unsavedChangesMsg), vendorName)),
                primaryButton: .destructive(Text(LocalizationKey.discardChanges)) { discardAndSwitch() },
                secondaryButton: .cancel(Text(LocalizationKey.keepEditing)) { pendingVendorId = nil }
            )
        case .error(let message):
            return Alert(
                title: Text(LocalizationKey.error),
                message: Text(message),
                dismissButton: .default(Text(LocalizationKey.ok))
            )
        }
    }
    
    private func attemptSelectionChange(to newId: String?) {
        guard newId != selectedVendorId else { return }
        if isDetailDirty {
            pendingVendorId = newId
            let currentName = viewModel.vendors.first(where: { $0.id == selectedVendorId })?.displayName ?? ""
            activeAlert = .unsavedChanges(vendorName: currentName)
        } else {
            withAnimation { selectedVendorId = newId }
        }
    }

    private func discardAndSwitch() {
        isDetailDirty = false
        withAnimation {
            selectedVendorId = pendingVendorId
            pendingVendorId = nil
        }
    }

    private func addNewVendor() {
        let newVendor = Vendor(id: UUID().uuidString.prefix(8).lowercased(), name: LocalizationKey.localized(LocalizationKey.defaultNewVendorName), env: [:])
        do {
            try viewModel.addVendor(newVendor)
            attemptSelectionChange(to: newVendor.id)
        } catch {
            activeAlert = .error(error.localizedDescription)
        }
    }

    private func handleSave(_ updatedVendor: Vendor) {
        do {
            try viewModel.updateVendor(updatedVendor)
        } catch {
            activeAlert = .error(error.localizedDescription)
        }
    }
    
    private func deleteVendor(_ vendor: Vendor) {
        do {
            try viewModel.removeVendor(with: vendor.id)
            if selectedVendorId == vendor.id {
                withAnimation {
                    selectedVendorId = nil
                    isDetailDirty = false
                }
            }
        } catch {
            activeAlert = .error(error.localizedDescription)
        }
    }

    private func duplicateVendor(_ vendor: Vendor) {
        do {
            try viewModel.duplicateVendor(vendor)
            // After duplication, the new vendor is added to the list
            // Find the new vendor (it's a copy)
            let suffix = LocalizationKey.localized(LocalizationKey.copySuffix)
            if let newVendor = viewModel.vendors.first(where: { $0.name.hasPrefix("\(vendor.displayName)\(suffix)") }) {
                attemptSelectionChange(to: newVendor.id)
            }
        } catch {
            activeAlert = .error(error.localizedDescription)
        }
    }
    
    @ViewBuilder
    private func vendorContextMenu(_ vendor: Vendor) -> some View {
        Button {
            viewModel.toggleFavorite(vendor.id)
        } label: {
            Text(LocalizedStringKey(viewModel.isFavorite(vendor.id) ? LocalizationKey.removeFromFavorites : LocalizationKey.addToFavorites))
        }
        Button { duplicateVendor(vendor) } label: { Text(LocalizedStringKey(LocalizationKey.duplicateVendor)) }
        Divider()
        Button { activeAlert = .deleteConfirmation(vendor) } label: { Text(LocalizedStringKey(LocalizationKey.delete)) }
            .disabled(vendor.id == viewModel.currentVendorId)
    }
}