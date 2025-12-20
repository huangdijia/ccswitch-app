import SwiftUI
import AppKit

struct SettingsView: View {
    @State private var selectedTab: SettingsTab? = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Section {
                    NavigationLink(value: SettingsTab.general) {
                        Label("general", systemImage: "gearshape")
                    }
                    NavigationLink(value: SettingsTab.vendors) {
                        Label("vendors", systemImage: "server.rack")
                    }
                    NavigationLink(value: SettingsTab.advanced) {
                        Label("advanced", systemImage: "wrench.and.screwdriver")
                    }
                } header: {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue)
                                .frame(width: 24, height: 24)
                            Text("CC")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("app_name")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                
                if let tab = selectedTab {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text(LocalizedStringKey(tabTitle(for: tab)))
                                    .font(.title2.bold())
                                Spacer()
                            }
                            .padding(.bottom, DesignSystem.Spacing.large)
                            
                            switch tab {
                            case .general:
                                GeneralSettingsView()
                            case .vendors:
                                VendorManagementView()
                            case .advanced:
                                AdvancedSettingsView()
                            }
                        }
                        .padding(DesignSystem.Spacing.xLarge)
                        .frame(maxWidth: 800) // ChatGPT style max width for readability
                    }
                } else {
                    Text("Select an option")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("")
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    private func tabTitle(for tab: SettingsTab) -> String {
        switch tab {
        case .general: return "general_settings"
        case .vendors: return "vendor_management_title"
        case .advanced: return "advanced_options"
        }
    }
}

enum SettingsTab: Hashable {
    case general
    case vendors
    case advanced
}
