import SwiftUI

struct SyncConflictResolverView: View {
    @ObservedObject private var syncManager = SyncManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(LocalizedStringKey("sync_conflict_title"))
                    .font(.headline)
                Spacer()
                if syncManager.pendingConflicts.isEmpty {
                    Button(LocalizedStringKey("done")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .controlSize(.small)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if syncManager.pendingConflicts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text(LocalizedStringKey("all_conflicts_resolved"))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(syncManager.pendingConflicts) { conflict in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(conflict.local.displayName)
                                .font(.headline)
                            
                            HStack(alignment: .top, spacing: 24) {
                                ConflictVersionView(
                                    title: "local_version",
                                    vendor: conflict.local,
                                    actionTitle: "keep_local",
                                    color: .blue
                                ) {
                                    syncManager.resolveConflict(vendorId: conflict.id, keepLocal: true)
                                }
                                
                                ConflictVersionView(
                                    title: "remote_version",
                                    vendor: conflict.remote,
                                    actionTitle: "keep_remote",
                                    color: .orange
                                ) {
                                    syncManager.resolveConflict(vendorId: conflict.id, keepLocal: false)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

struct ConflictVersionView: View {
    let title: String
    let vendor: Vendor
    let actionTitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(title))
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vendor.name)
                    .font(.subheadline.weight(.medium))
                Text(String(format: NSLocalizedString("env_vars_count", comment: ""), vendor.env.count))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.1))
            .cornerRadius(6)
            
            Button(LocalizedStringKey(actionTitle)) {
                action()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(color)
        }
        .frame(maxWidth: .infinity)
    }
}
