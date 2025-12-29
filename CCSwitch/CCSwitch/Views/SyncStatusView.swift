import SwiftUI

struct SyncStatusView: View {
    let status: SyncStatus

    var body: some View {
        switch status {
        case .idle:
            Text(LocalizedStringKey(LocalizationKey.syncIdle))
                .font(.caption)
                .foregroundColor(.secondary)
        case .syncing:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
                Text(LocalizedStringKey(LocalizationKey.syncSyncing))
                    .font(.caption)
            }
            .foregroundColor(.accentColor)
        case .success:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.icloud")
                Text(LocalizedStringKey(LocalizationKey.syncSuccess))
                    .font(.caption)
            }
            .foregroundColor(.green)
        case .offline:
            HStack(spacing: 4) {
                Image(systemName: "wifi.slash")
                Text(LocalizedStringKey(LocalizationKey.syncOffline))
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        case .error(let msg):
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.icloud")
                Text(String(format: NSLocalizedString(LocalizationKey.syncError, comment: ""), msg))
                    .font(.caption)
            }
            .foregroundColor(.red)
        }
    }
}

