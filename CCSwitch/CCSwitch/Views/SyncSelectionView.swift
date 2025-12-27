import SwiftUI

struct SyncSelectionView: View {
    @ObservedObject private var syncManager = SyncManager.shared
    @ObservedObject private var configManager = ConfigManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(LocalizedStringKey("sync_selection_title"))
                    .font(.headline)
                Spacer()
                Button(LocalizedStringKey("done")) {
                    presentationMode.wrappedValue.dismiss()
                }
                .controlSize(.small)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            List {
                Section(header: Text(LocalizedStringKey("vendors"))) {
                    if configManager.allVendors.isEmpty {
                        Text(LocalizedStringKey("no_vendors"))
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(configManager.allVendors) { vendor in
                            Toggle(isOn: Binding(
                                get: { syncManager.syncConfig.syncedVendorIds.contains(vendor.id) },
                                set: { isOn in
                                    var ids = syncManager.syncConfig.syncedVendorIds
                                    if isOn {
                                        if !ids.contains(vendor.id) {
                                            ids.append(vendor.id)
                                        }
                                    } else {
                                        ids.removeAll { $0 == vendor.id }
                                    }
                                    syncManager.updateSyncedVendors(ids: ids)
                                }
                            )) {
                                Text(vendor.displayName)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}
