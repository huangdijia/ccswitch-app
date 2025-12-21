import SwiftUI

struct VendorManagementView: View {
    @State private var vendors: [Vendor] = []
    @State private var selectedVendor: Vendor?
    @State private var hasLegacyConfig: Bool = false
    @State private var showImportError: Bool = false
    @State private var importErrorMessage: String = ""
    @State private var showImportSuccess: Bool = false
    @State private var importedCount: Int = 0
    @State private var activeSheet: SheetState?
    @State private var currentVendorId: String = ""
    @State private var showDeleteConfirmation: Bool = false
    @State private var vendorToDelete: Vendor?
    
    enum SheetState: Identifiable {
        case detail(Vendor)
        case edit(Vendor?)
        
        var id: String {
            switch self {
            case .detail(let v): return "detail-\(v.id)"
            case .edit(let v): return "edit-\(v?.id ?? "new")"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if hasLegacyConfig {
                Button(action: importLegacyConfig) {
                    HStack {
                        Image(systemName: "arrow.down.doc")
                        Text("import_legacy_config_button")
                    }
                    .font(DesignSystem.Fonts.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(DesignSystem.Colors.accent.opacity(0.1))
                    .foregroundColor(DesignSystem.Colors.accent)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(DesignSystem.Colors.accent.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, DesignSystem.Spacing.large)
            }

            ModernSection(title: "vendors") {
                if vendors.isEmpty {
                    Text("no_vendors_found")
                        .font(DesignSystem.Fonts.body)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .padding(DesignSystem.Spacing.large)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(Array(vendors.enumerated()), id: \.element.id) { index, vendor in
                        VendorRow(
                            vendor: vendor,
                            isCurrent: vendor.id == currentVendorId,
                            onSwitch: {
                                try? ConfigManager.shared.switchToVendor(with: vendor.id)
                                loadVendors()
                            },
                            onEdit: {
                                activeSheet = .detail(vendor)
                            },
                            onDelete: {
                                vendorToDelete = vendor
                                showDeleteConfirmation = true
                            }
                        )
                        if index < vendors.count - 1 {
                            ModernDivider()
                        }
                    }
                }
            }
            
            // Add Vendor Button
            Button(action: {
                activeSheet = .edit(nil)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("add_vendor")
                }
                .font(DesignSystem.Fonts.body.weight(.medium))
                .foregroundColor(DesignSystem.Colors.accent)
                .padding(.vertical, DesignSystem.Spacing.medium)
                .frame(maxWidth: .infinity)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(DesignSystem.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, DesignSystem.Spacing.medium)
            
            Spacer()
        }
        .onAppear {
            loadVendors()
        }
        .onReceive(NotificationCenter.default.publisher(for: .configDidChange)) { _ in
            loadVendors()
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .detail(let vendor):
                VendorDetailView(
                    vendor: vendor,
                    isCurrent: vendor.id == currentVendorId,
                    onEdit: {
                        // Close detail and open edit
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            activeSheet = .edit(vendor)
                        }
                    },
                    onDelete: {
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            vendorToDelete = vendor
                            showDeleteConfirmation = true
                        }
                    }
                )
            case .edit(let vendor):
                VendorEditView(
                    vendor: vendor,
                    onSave: { newVendor in
                        do {
                            if let _ = vendor {
                                try ConfigManager.shared.updateVendor(newVendor)
                            } else {
                                try ConfigManager.shared.addVendor(newVendor)
                            }
                            loadVendors()
                            activeSheet = nil
                        } catch {
                            // TODO: Show error in edit view
                            print("Error saving vendor: \(error)")
                        }
                    },
                    onCancel: {
                        activeSheet = nil
                    }
                )
            }
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("confirm_delete_title"),
                message: Text("confirm_delete_msg"),
                primaryButton: .destructive(Text("delete")) {
                    if let vendor = vendorToDelete {
                        do {
                            try ConfigManager.shared.removeVendor(with: vendor.id)
                            loadVendors()
                        } catch {
                            // TODO: Handle error
                            print("Error deleting vendor: \(error)")
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showImportError) {
            Alert(
                title: Text("error"),
                message: Text(importErrorMessage),
                dismissButton: .default(Text("ok"))
            )
        }
        .alert(isPresented: $showImportSuccess) {
            Alert(
                title: Text("success"),
                message: Text("Successfully imported \(importedCount) vendors."),
                dismissButton: .default(Text("ok"))
            )
        }
    }

    private func loadVendors() {
        vendors = ConfigManager.shared.allVendors
        currentVendorId = ConfigManager.shared.currentVendor?.id ?? ""
        hasLegacyConfig = ConfigManager.shared.hasLegacyConfig
    }
    
    private func importLegacyConfig() {
        do {
            importedCount = try ConfigManager.shared.migrateFromLegacy()
            showImportSuccess = true
            loadVendors()
        } catch {
            importErrorMessage = error.localizedDescription
            showImportError = true
        }
    }
}

struct VendorRow: View {
    let vendor: Vendor
    let isCurrent: Bool
    let onSwitch: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vendor.displayName)
                    .font(DesignSystem.Fonts.body.weight(.medium))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isCurrent },
                set: { newValue in
                    if newValue {
                        onSwitch()
                    }
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .disabled(isCurrent)
            .padding(.trailing, 8)
            
            HStack(spacing: 4) {
                Button(action: onEdit) {
                    Image(systemName: "info.circle")
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
                .help("details_tooltip")
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(DesignSystem.Colors.error.opacity(0.8))
                        .font(.system(size: 15))
                }
                .buttonStyle(PlainButtonStyle())
                .help("delete_vendor")
                .disabled(isCurrent) // Cannot delete active vendor
                .opacity(isCurrent ? 0.3 : 1.0)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .background(isHovered ? Color.gray.opacity(0.05) : Color.clear)
        .onHover { hover in
            isHovered = hover
        }
    }
}

// MARK: - Vendor Detail View
struct VendorDetailView: View {
    let vendor: Vendor
    let isCurrent: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vendor.displayName)
                        .font(.title3.bold())
                }
                Spacer()
                
                if !isCurrent {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("delete_vendor")
                    .padding(.trailing, 16)
                }
                
                Button(action: onEdit) {
                    Text("edit_vendor")
                        .font(DesignSystem.Fonts.body)
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.trailing, 8)

                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(DesignSystem.Spacing.large)
            
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    ModernSection(title: "environment_variables") {
                        let sortedKeys = vendor.env.keys.sorted()
                        if sortedKeys.isEmpty {
                            Text("No environment variables")
                                .font(DesignSystem.Fonts.body)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                                .padding(DesignSystem.Spacing.medium)
                        } else {
                            ForEach(0..<sortedKeys.count, id: \.self) { index in
                                let key = sortedKeys[index]
                                DetailRowItem(label: key, value: vendor.env[key] ?? "")
                                if index < sortedKeys.count - 1 {
                                    ModernDivider()
                                }
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.large)
            }

            Divider()

            HStack(spacing: DesignSystem.Spacing.medium) {
                Spacer()
                Button("close_button") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())

                if !isCurrent {
                    Button("switch_to_vendor_button") {
                        try? ConfigManager.shared.switchToVendor(with: vendor.id)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(DesignSystem.Spacing.large)
        }
        .frame(width: 400, height: 500)
        .background(DesignSystem.Colors.background)
    }
}

struct DetailRowItem: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(LocalizedStringKey(label))
                .font(DesignSystem.Fonts.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DesignSystem.Fonts.body.monospaced())
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.medium)
    }
}