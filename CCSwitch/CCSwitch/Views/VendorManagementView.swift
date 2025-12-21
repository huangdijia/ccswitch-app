import SwiftUI

struct VendorManagementView: View {
    @State private var vendors: [Vendor] = []
    @State private var selection: Set<String> = []
    @State private var activeSheet: SheetState?
    @State private var currentVendorId: String = ""
    @State private var showDeleteConfirmation: Bool = false
    
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
        VStack(spacing: 0) {
            HStack {
                Text(LocalizedStringKey("vendor_list"))
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            // Unified List and Toolbar Container
            List(selection: $selection) {
                ForEach(vendors) { vendor in
                    HStack {
                        Circle()
                            .fill(colorForVendor(vendor.id))
                            .frame(width: 10, height: 10)
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                        
                        Text(vendor.displayName)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .padding(.leading, 4)
                        
                        Spacer()
                        
                        Group {
                            if vendor.id == currentVendorId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14))
                            }
                        }
                        .frame(width: 24)
                    }
                    .padding(.vertical, 2)
                    .tag(vendor.id)
                    .onTapGesture(count: 2) {
                         activeSheet = .edit(vendor)
                    }
                    .contextMenu {
                        Button(LocalizedStringKey("edit_vendor")) {
                            activeSheet = .edit(vendor)
                        }
                        
                        Button(LocalizedStringKey("set_active")) {
                            try? ConfigManager.shared.switchToVendor(with: vendor.id)
                            loadVendors()
                        }
                        .disabled(vendor.id == currentVendorId)
                        
                        Button(LocalizedStringKey(ConfigManager.shared.isFavorite(vendor.id) ? "remove_from_favorites" : "add_to_favorites")) {
                            ConfigManager.shared.toggleFavorite(vendor.id)
                            loadVendors()
                        }
                        
                        Divider()
                        
                        Button(LocalizedStringKey("delete_vendor")) {
                            selection = [vendor.id]
                            showDeleteConfirmation = true
                        }
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .frame(height: max(200, CGFloat(vendors.count * 30)))
            .border(Color(NSColor.separatorColor), width: 1)
            .padding(.horizontal, 20)
            
            // Bottom Toolbar
            HStack(spacing: 0) {
                // Segmented-style control group
                HStack(spacing: 0) {
                    Button(action: { activeSheet = .edit(nil) }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 26, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Add Vendor")
                    
                    Divider()
                        .frame(height: 14)
                    
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 26, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(selection.isEmpty)
                    .opacity(selection.isEmpty ? 0.5 : 1.0)
                    .help("Delete Vendor")
                    
                    Divider()
                        .frame(height: 14)
                    
                    Button(action: {
                        if let id = selection.first, let vendor = vendors.first(where: { $0.id == id }) {
                            activeSheet = .edit(vendor)
                        }
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 26, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(selection.count != 1)
                    .opacity(selection.count != 1 ? 0.5 : 1.0)
                    .help("Edit Vendor")
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
                
                Spacer()
                
                if selection.count == 1 {
                    Button(action: {
                        if let id = selection.first {
                             try? ConfigManager.shared.switchToVendor(with: id)
                             loadVendors()
                        }
                    }) {
                        Text(LocalizedStringKey("set_active"))
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                    }
                    .disabled(selection.first == currentVendorId)
                    .padding(.trailing, 0)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 0)
            
            Spacer()
            
            Divider()
            
            // Favorites / Tags Area
            VStack(alignment: .leading, spacing: 10) {
                Text(LocalizedStringKey("favorite_vendors"))
                    .font(.headline)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
                
                if ConfigManager.shared.favoriteVendors.isEmpty {
                     Text(LocalizedStringKey("drag_favorite_hint")) // Keeping the hint, or update it
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ConfigManager.shared.favoriteVendors) { vendor in
                                 Button(action: {
                                     try? ConfigManager.shared.switchToVendor(with: vendor.id)
                                     loadVendors()
                                 }) {
                                     HStack(spacing: 6) {
                                         Circle()
                                             .fill(colorForVendor(vendor.id))
                                             .frame(width: 8, height: 8)
                                         Text(vendor.displayName)
                                             .font(.caption)
                                             .foregroundColor(.primary)
                                     }
                                     .padding(.horizontal, 10)
                                     .padding(.vertical, 6)
                                     .background(vendor.id == currentVendorId ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                                     .cornerRadius(12)
                                     .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(vendor.id == currentVendorId ? Color.blue : Color(NSColor.separatorColor), lineWidth: 1)
                                     )
                                 }
                                 .buttonStyle(.plain)
                                 .contextMenu {
                                     Button(LocalizedStringKey("remove_from_favorites")) {
                                         ConfigManager.shared.toggleFavorite(vendor.id)
                                         loadVendors()
                                     }
                                 }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(minHeight: 80)
            .background(Color(NSColor.windowBackgroundColor))
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
                VendorEditView(vendor: vendor, onSave: handleSave, onCancel: { activeSheet = nil })
            case .edit(let vendor):
                VendorEditView(vendor: vendor, onSave: handleSave, onCancel: { activeSheet = nil })
            }
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text(LocalizedStringKey("confirm_delete_title")),
                message: Text(LocalizedStringKey("confirm_delete_msg")),
                primaryButton: .destructive(Text(LocalizedStringKey("delete"))) {
                    deleteSelectedVendors()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func loadVendors() {
        vendors = ConfigManager.shared.allVendors
        currentVendorId = ConfigManager.shared.currentVendor?.id ?? ""
    }
    
    private func handleSave(_ newVendor: Vendor) {
        do {
            if vendors.contains(where: { $0.id == newVendor.id }) {
                 try ConfigManager.shared.updateVendor(newVendor)
            } else {
                 try ConfigManager.shared.addVendor(newVendor)
            }
            loadVendors()
            activeSheet = nil
        } catch {
            print("Error saving vendor: \(error)")
        }
    }
    
    private func deleteSelectedVendors() {
        for id in selection {
            try? ConfigManager.shared.removeVendor(with: id)
        }
        selection.removeAll()
        loadVendors()
    }

    private func colorForVendor(_ id: String) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .gray]
        let hash = abs(id.hashValue)
        return colors[hash % colors.count]
    }
}
