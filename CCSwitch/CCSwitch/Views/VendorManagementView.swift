import SwiftUI

struct VendorManagementView: View {
    @State private var vendors: [Vendor] = []
    @State private var selectedVendor: Vendor?
    private let currentVendorId = ConfigManager.shared.currentVendor?.id ?? ""

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
            // Header Section
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "server.rack")
                        .foregroundColor(DesignSystem.Colors.accent)
                        .font(.system(size: 20, weight: .semibold))

                    Text("vendor_management_title")
                        .font(DesignSystem.Fonts.title)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Spacer()
                }

                Text("vendor_management_subtitle")
                    .font(DesignSystem.Fonts.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .font(.caption)
                    Text("config_path_label")
                        .font(.caption)
                        .monospaced()
                }
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)

            // Vendor List
            if vendors.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.medium) {
                        ForEach(vendors) { vendor in
                            VendorCard(
                                vendor: vendor,
                                isCurrent: vendor.id == currentVendorId,
                                onSwitch: {
                                    try? ConfigManager.shared.switchToVendor(with: vendor.id)
                                    loadVendors()
                                },
                                onDetail: {
                                    selectedVendor = vendor
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 20)
                }
            }
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
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.warning.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(DesignSystem.Colors.warning)
            }

            Text("no_vendors_found")
                .font(DesignSystem.Fonts.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Text("check_config_msg")
                .font(DesignSystem.Fonts.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

// MARK: - Vendor Card
struct VendorCard: View {
    let vendor: Vendor
    let isCurrent: Bool
    let onSwitch: () -> Void
    let onDetail: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Icon
            ZStack {
                Circle()
                    .fill(isCurrent ? DesignSystem.Colors.success.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)

                if isCurrent {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.success)
                } else {
                    Text(String(vendor.displayName.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gray)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(vendor.displayName)
                        .font(DesignSystem.Fonts.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    if isCurrent {
                        Text("active_badge")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(DesignSystem.Colors.success))
                    }
                }

                HStack(spacing: 12) {
                    Label(vendor.claudeSettingsPatch.model, systemImage: "cpu")
                    if let baseURL = vendor.claudeSettingsPatch.baseURL {
                         Label(baseURL, systemImage: "link")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .font(DesignSystem.Fonts.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            // Actions
            HStack(spacing: DesignSystem.Spacing.small) {
                Button(action: onDetail) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                        .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .help("details_tooltip")

                if !isCurrent {
                    Button(action: onSwitch) {
                        Text("switch_button")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(DesignSystem.Colors.surface)
                .shadow(color: isHovered ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: isHovered ? 8 : 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(isCurrent ? DesignSystem.Colors.success.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
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
            // Header
            ZStack {
                Color(NSColor.windowBackgroundColor)
                
                VStack(spacing: DesignSystem.Spacing.medium) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.accent)
                        .padding(.top, 20)
                    
                    Text(vendor.displayName)
                        .font(DesignSystem.Fonts.title)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if isCurrent {
                        Text("currently_active")
                            .font(DesignSystem.Fonts.caption)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.success)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(DesignSystem.Colors.success.opacity(0.1)))
                    }
                }
                .padding(.bottom, 20)
            }
            .frame(height: 180)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    DetailSection(title: NSLocalizedString("configuration", comment: "")) {
                        DetailRow(label: NSLocalizedString("provider_label", comment: ""), value: vendor.claudeSettingsPatch.provider)
                        DetailRow(label: NSLocalizedString("model_label", comment: ""), value: vendor.claudeSettingsPatch.model)
                        DetailRow(label: NSLocalizedString("api_key_env_label", comment: ""), value: vendor.claudeSettingsPatch.apiKeyEnv)
                        if let baseURL = vendor.claudeSettingsPatch.baseURL {
                            DetailRow(label: NSLocalizedString("base_url_label", comment: ""), value: baseURL)
                        }
                    }
                    
                    if let notes = vendor.notes, !notes.isEmpty {
                        DetailSection(title: NSLocalizedString("notes_label", comment: "")) {
                            Text(notes)
                                .font(DesignSystem.Fonts.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .padding(DesignSystem.Spacing.small)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DesignSystem.Colors.secondarySurface)
                                .cornerRadius(DesignSystem.CornerRadius.small)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.large)
            }

            Divider()

            // Footer Actions
            HStack(spacing: DesignSystem.Spacing.medium) {
                Button("close_button") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                .keyboardShortcut(.escape, modifiers: [])

                if !isCurrent {
                    Button("switch_to_vendor_button") {
                        try? ConfigManager.shared.switchToVendor(with: vendor.id)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surface)
        }
        .frame(width: 500, height: 600)
        .background(DesignSystem.Colors.surface)
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text(title)
                .font(DesignSystem.Fonts.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: 1) {
                content()
            }
            .background(DesignSystem.Colors.secondarySurface)
            .cornerRadius(DesignSystem.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Fonts.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(DesignSystem.Fonts.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
    }
}
