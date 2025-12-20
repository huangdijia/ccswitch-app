import SwiftUI

struct VendorManagementView: View {
    @State private var vendors: [Vendor] = []
    @State private var selectedVendor: Vendor?
    @State private var hasLegacyConfig: Bool = false
    @State private var showImportError: Bool = false
    @State private var importErrorMessage: String = ""
    @State private var showImportSuccess: Bool = false
    private let currentVendorId = ConfigManager.shared.currentVendor?.id ?? ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Summary Tip
            Text("vendor_management_subtitle")
                .font(DesignSystem.Fonts.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.bottom, DesignSystem.Spacing.large)

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
                        message: Text("migration_success"),
                        dismissButton: .default(Text("ok"))
                    )
                }
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
                                selectedVendor = vendor
                            }
                        )
                        if index < vendors.count - 1 {
                            ModernDivider()
                        }
                    }
                }
            }
            
            // Footer Info
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                Text("config_path_label")
            }
            .font(DesignSystem.Fonts.caption)
            .foregroundColor(DesignSystem.Colors.textTertiary)
            .padding(.leading, 4)
        }
        .onAppear {
            loadVendors()
        }
        .sheet(item: $selectedVendor) { vendor in
            VendorDetailView(vendor: vendor, isCurrent: vendor.id == currentVendorId)
        }
    }

    private func loadVendors() {
        vendors = ConfigManager.shared.allVendors
        // Only show legacy import if we are running on default config (which implies no user config yet) or if explicitly checking for legacy file existence
        // But logic says: "If ~/.ccswitch/ccs.json exists, show button".
        // Use a simpler check:
        hasLegacyConfig = ConfigManager.shared.hasLegacyConfig
    }
    
    private func importLegacyConfig() {
        do {
            try ConfigManager.shared.migrateFromLegacy()
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
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Icon Placeholder / Leading
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isCurrent ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)
                Text(String(vendor.displayName.prefix(1)).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isCurrent ? .blue : .gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(vendor.displayName)
                        .font(DesignSystem.Fonts.body.weight(.medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if isCurrent {
                        Text("active_badge")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.blue))
                            .foregroundColor(.white)
                    }
                }
                
                Text(vendor.env["ANTHROPIC_MODEL"] ?? vendor.env["model"] ?? "default")
                    .font(DesignSystem.Fonts.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            if !isCurrent {
                Button(action: onSwitch) {
                    Text("switch_button")
                        .font(DesignSystem.Fonts.caption.weight(.medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.small)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: onEdit) {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
            .help("details_tooltip")
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
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vendor.displayName)
                        .font(.title3.bold())
                    Text("configuration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
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
                    
                    if let notes = vendor.notes, !notes.isEmpty {
                        ModernSection(title: "notes_label") {
                            Text(notes)
                                .font(DesignSystem.Fonts.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .padding(DesignSystem.Spacing.medium)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
