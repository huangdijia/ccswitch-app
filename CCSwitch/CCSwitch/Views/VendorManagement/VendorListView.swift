import SwiftUI

/// Sidebar list view for displaying vendors
struct VendorListView: View {
    @ObservedObject var viewModel: DefaultVendorManagementViewModel
    @Binding var selectedVendorId: String?
    let onDelete: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            Divider()

            // Vendor list
            vendorList

            // Bottom toolbar
            bottomToolbar
        }
        .frame(width: 200)
        .background(.thinMaterial)
    }

    // MARK: - Search Bar

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

    // MARK: - Vendor List

    private var vendorList: some View {
        List(selection: $selectedVendorId) {
            if !viewModel.favoriteVendors.isEmpty {
                Section(LocalizationKey.favorites) {
                    ForEach(viewModel.favoriteVendors) { vendor in
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
                    }
                }
            }

            Section(LocalizationKey.allVendors) {
                ForEach(viewModel.otherVendors) { vendor in
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
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .frame(minWidth: 200)
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .contentShape(Rectangle())
                    .frame(width: 30, height: 28)
            }
            .buttonStyle(.plain)
            .help(LocalizationKey.localized(LocalizationKey.addVendor))

            Divider().frame(height: 16)

            Button(action: onDelete) {
                Image(systemName: "minus")
                    .contentShape(Rectangle())
                    .frame(width: 30, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(selectedVendorId == nil || selectedVendorId == viewModel.currentVendorId)
            .help(LocalizationKey.localized(LocalizationKey.deleteVendor))

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
}
