import SwiftUI

/// Row view for displaying a single vendor in the vendor list
struct VendorRowView: View {
    let vendor: Vendor
    let isActive: Bool
    let isFavorite: Bool
    let isPreset: Bool
    let onToggleFavorite: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack {
            // Status indicator
            if isActive {
                Circle().fill(Color.green).frame(width: 8, height: 8)
            } else {
                Circle().strokeBorder(Color.secondary, lineWidth: 1).frame(width: 8, height: 8)
            }

            // Vendor info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(vendor.displayName).font(.body).lineLimit(1)
                    if isPreset {
                        Text(LocalizedStringKey(LocalizationKey.presetLabel))
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                }
                if let url = vendor.env["ANTHROPIC_BASE_URL"],
                   let host = URL(string: url)?.host {
                    Text(host).font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
            }

            Spacer()

            // Favorite star
            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                    .onTapGesture { onToggleFavorite() }
            } else if isHovered {
                Image(systemName: "star")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .onTapGesture { onToggleFavorite() }
            }
        }
        .padding(.vertical, 4)
        .onHover { isHovered = $0 }
    }
}
