import SwiftUI

struct SyncStatusView: View {
    let status: SyncManager.SyncStatus
    
    var body: some View {
        switch status {
        case .idle:
            Text(LocalizedStringKey("sync_idle"))
                .font(.caption)
                .foregroundColor(.secondary)
        case .syncing:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
                Text(LocalizedStringKey("sync_syncing"))
                    .font(.caption)
            }
            .foregroundColor(.accentColor)
        case .success:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.icloud")
                Text(LocalizedStringKey("sync_success"))
                    .font(.caption)
            }
            .foregroundColor(.green)
        case .offline:
            HStack(spacing: 4) {
                Image(systemName: "wifi.slash")
                Text(LocalizedStringKey("sync_offline"))
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        case .error(let msg):
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.icloud")
                Text(String(format: NSLocalizedString("sync_error", comment: ""), msg))
                    .font(.caption)
            }
            .foregroundColor(.red)
        }
    }
}
