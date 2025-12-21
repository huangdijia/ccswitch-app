import SwiftUI

struct VendorManagementView: View {
    @State private var vendors: [Vendor] = []
    @State private var selectedVendorId: String? // The "official" selection
    @State private var searchText = ""
    @State private var currentVendorId: String = ""
    @State private var showDeleteConfirmation = false
    @State private var vendorToDelete: Vendor?

    // Navigation Guard State
    @State private var isDetailDirty: Bool = false
    @State private var pendingVendorId: String? = nil
    @State private var showUnsavedChangesAlert = false
    
    // Error Handling
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    // Filtered vendors based on search text
    var filteredVendors: [Vendor] {
        if searchText.isEmpty {
            return vendors
        } else {
            return vendors.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var favoriteVendors: [Vendor] {
        filteredVendors.filter { ConfigManager.shared.isFavorite($0.id) }
    }
    
    var otherVendors: [Vendor] {
        filteredVendors.filter { !ConfigManager.shared.isFavorite($0.id) }
    }

    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Sidebar (List)
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("search_vendors", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(NSColor.separatorColor)),
                    alignment: .bottom
                )
                
                // Binding wrapper to intercept selection changes
                let selectionBinding = Binding<String?>(
                    get: { selectedVendorId },
                    set: { newValue in
                        attemptSelectionChange(to: newValue)
                    }
                )
                
                List(selection: selectionBinding) {
                    if !favoriteVendors.isEmpty {
                        Section("favorites") {
                            ForEach(favoriteVendors) { vendor in
                                VendorRowView(vendor: vendor, isActive: vendor.id == currentVendorId)
                                    .tag(vendor.id)
                                    .contextMenu { vendorContextMenu(vendor) }
                            }
                        }
                    }
                    
                    Section("all_vendors") {
                        ForEach(otherVendors) { vendor in
                            VendorRowView(vendor: vendor, isActive: vendor.id == currentVendorId)
                                .tag(vendor.id)
                                .contextMenu { vendorContextMenu(vendor) }
                        }
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .frame(minWidth: 200)
                // Attach Unsaved Changes Alert here
                .alert(isPresented: $showUnsavedChangesAlert) {
                    let vendorName = vendors.first(where: { $0.id == selectedVendorId })?.displayName ?? "Item"
                    return Alert(
                        title: Text("unsaved_changes"),
                        message: Text(String(format: NSLocalizedString("unsaved_changes_msg", comment: ""), vendorName)),
                        primaryButton: .destructive(Text("discard_changes")) {
                            discardAndSwitch()
                        },
                        secondaryButton: .cancel(Text("keep_editing")) {
                            pendingVendorId = nil
                        }
                    )
                }
                
                // Bottom Toolbar
                HStack(spacing: 0) {
                    Button(action: addNewVendor) {
                        Image(systemName: "plus")
                            .frame(width: 30, height: 28)
                    }
                    .buttonStyle(.plain)
                    
                    Divider().frame(height: 16)
                    
                    Button(action: {
                        if let id = selectedVendorId, let v = vendors.first(where: { $0.id == id }) {
                            confirmDelete(v)
                        }
                    }) {
                        Image(systemName: "minus")
                            .frame(width: 30, height: 28)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedVendorId == nil || selectedVendorId == currentVendorId)
                    
                    Spacer()
                }
                .background(Color(NSColor.controlBackgroundColor))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(NSColor.separatorColor)),
                    alignment: .top
                )
                // Attach Delete Confirmation Alert here
                .alert(isPresented: $showDeleteConfirmation) {
                    Alert(
                        title: Text("delete_vendor"),
                        message: Text(String(format: NSLocalizedString("delete_vendor_confirmation", comment: ""), vendorToDelete?.displayName ?? "")),
                        primaryButton: .destructive(Text("delete")) {
                            if let v = vendorToDelete {
                                deleteVendor(v)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .frame(width: 200)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // MARK: - Right Detail View
            Group {
                if let selectedId = selectedVendorId, let vendor = vendors.first(where: { $0.id == selectedId }) {
                    VendorDetailView(
                        vendor: vendor,
                        isActive: vendor.id == currentVendorId,
                        isDirtyBinding: $isDetailDirty,
                        onSave: handleSave
                    )
                    .id(selectedId)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("no_vendor_selected")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("no_vendor_selected_desc")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.windowBackgroundColor))
                }
            }
            .frame(maxWidth: .infinity)
            // Attach Error Alert here
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("error"),
                    message: Text(errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("ok"))
                )
            }
        }
        .onAppear {
            loadVendors()
            if selectedVendorId == nil, let first = vendors.first {
                selectedVendorId = first.id
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .configDidChange)) { _ in
            loadVendors()
        }
    }
    
    // MARK: - Navigation Guard Logic
    
    private func attemptSelectionChange(to newId: String?) {
        guard newId != selectedVendorId else { return }
        
        if isDetailDirty {
            pendingVendorId = newId
            showUnsavedChangesAlert = true
        } else {
            selectedVendorId = newId
        }
    }
    
    private func discardAndSwitch() {
        if let newId = pendingVendorId {
            isDetailDirty = false
            selectedVendorId = newId
            pendingVendorId = nil
        }
    }
    
    // MARK: - Actions
    
    private func loadVendors() {
        vendors = ConfigManager.shared.allVendors
        currentVendorId = ConfigManager.shared.currentVendor?.id ?? ""
    }
    
    private func addNewVendor() {
        if isDetailDirty {
             pendingVendorId = nil
        }
        
        let newVendor = Vendor(
            id: UUID().uuidString.prefix(8).lowercased(),
            name: "New Vendor",
            env: [:]
        )
        try? ConfigManager.shared.addVendor(newVendor)
        loadVendors()
        attemptSelectionChange(to: newVendor.id)
    }
    
    private func handleSave(_ updatedVendor: Vendor) {
        try? ConfigManager.shared.updateVendor(updatedVendor)
        loadVendors()
    }
    
    private func confirmDelete(_ vendor: Vendor) {
        if vendor.id == currentVendorId { return }
        vendorToDelete = vendor
        showDeleteConfirmation = true
    }
    
    private func deleteVendor(_ vendor: Vendor) {
        do {
            try ConfigManager.shared.removeVendor(with: vendor.id)
            if selectedVendorId == vendor.id {
                selectedVendorId = nil
                isDetailDirty = false
            }
            loadVendors()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }
    
    private func duplicateVendor(_ vendor: Vendor) {
        let newEnv = vendor.env
        let newId = UUID().uuidString.prefix(8).lowercased()
        let newName = "\(vendor.displayName) Copy"
        let newVendor = Vendor(id: newId, name: newName, env: newEnv)
        try? ConfigManager.shared.addVendor(newVendor)
        loadVendors()
        attemptSelectionChange(to: newId)
    }
    
    @ViewBuilder
    private func vendorContextMenu(_ vendor: Vendor) -> some View {
        Button {
            ConfigManager.shared.toggleFavorite(vendor.id)
            loadVendors()
        } label: {
            Text(ConfigManager.shared.isFavorite(vendor.id) ? "remove_from_favorites" : "add_to_favorites")
        }
        
        Button {
            duplicateVendor(vendor)
        } label: {
            Text("duplicate_vendor")
        }
        
        Divider()
        
        Button {
            confirmDelete(vendor)
        } label: {
            Text("delete")
        }
        .disabled(vendor.id == currentVendorId)
    }
}

// MARK: - Subviews (Unchanged)
struct VendorRowView: View {
    let vendor: Vendor
    let isActive: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            if isActive {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .strokeBorder(Color.secondary, lineWidth: 1)
                    .frame(width: 8, height: 8)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(vendor.displayName)
                    .font(.body)
                    .lineLimit(1)
                
                if let url = vendor.env["ANTHROPIC_BASE_URL"] ?? vendor.env["NTHROPIC_BASE_URL"],
                   let host = URL(string: url)?.host {
                    Text(host)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if ConfigManager.shared.isFavorite(vendor.id) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            } else if isHovered {
                Image(systemName: "star")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .onTapGesture {
                        ConfigManager.shared.toggleFavorite(vendor.id)
                    }
            }
        }
        .padding(.vertical, 4)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct VendorDetailView: View {
    let vendor: Vendor
    let isActive: Bool
    @Binding var isDirtyBinding: Bool // Reports dirty state to parent
    let onSave: (Vendor) -> Void
    
    // Internal State for Editing
    @State private var originalVendor: Vendor
    @State private var name: String
    @State private var baseURL: String
    @State private var authToken: String
    @State private var timeout: String
    @State private var defaultModel: String
    @State private var opusModel: String
    @State private var sonnetModel: String
    @State private var haikuModel: String
    @State private var smallFastModel: String
    
    // UI State
    @State private var showAdvancedModels = false
    @State private var showToken = false
    @State private var validationErrors: [String: String] = [:]
    
    // Connection Test
    @State private var isTesting = false
    @State private var testResult: Bool?
    @State private var testMessage: String?

    init(vendor: Vendor, isActive: Bool, isDirtyBinding: Binding<Bool>, onSave: @escaping (Vendor) -> Void) {
        self.vendor = vendor
        self.isActive = isActive
        self._isDirtyBinding = isDirtyBinding
        self.onSave = onSave
        
        // Initialize state
        _originalVendor = State(initialValue: vendor)
        _name = State(initialValue: vendor.name)
        let env = vendor.env
        _baseURL = State(initialValue: env["ANTHROPIC_BASE_URL"] ?? env["NTHROPIC_BASE_URL"] ?? "")
        _authToken = State(initialValue: env["ANTHROPIC_AUTH_TOKEN"] ?? "")
        _timeout = State(initialValue: env["API_TIMEOUT_MS"] ?? "")
        _defaultModel = State(initialValue: env["ANTHROPIC_MODEL"] ?? "")
        _opusModel = State(initialValue: env["ANTHROPIC_DEFAULT_OPUS_MODEL"] ?? "")
        _sonnetModel = State(initialValue: env["ANTHROPIC_DEFAULT_SONNET_MODEL"] ?? "")
        _haikuModel = State(initialValue: env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] ?? "")
        _smallFastModel = State(initialValue: env["ANTHROPIC_SMALL_FAST_MODEL"] ?? "")
    }
    
    // Computed dirty state
    private var isDirty: Bool {
        name != originalVendor.name ||
        baseURL != (originalVendor.env["ANTHROPIC_BASE_URL"] ?? originalVendor.env["NTHROPIC_BASE_URL"] ?? "") ||
        authToken != (originalVendor.env["ANTHROPIC_AUTH_TOKEN"] ?? "") ||
        timeout != (originalVendor.env["API_TIMEOUT_MS"] ?? "") ||
        defaultModel != (originalVendor.env["ANTHROPIC_MODEL"] ?? "") ||
        opusModel != (originalVendor.env["ANTHROPIC_DEFAULT_OPUS_MODEL"] ?? "") ||
        sonnetModel != (originalVendor.env["ANTHROPIC_DEFAULT_SONNET_MODEL"] ?? "") ||
        haikuModel != (originalVendor.env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] ?? "") ||
        smallFastModel != (originalVendor.env["ANTHROPIC_SMALL_FAST_MODEL"] ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(name.isEmpty ? "Untitled" : name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if isDirty {
                        Text("unsaved_changes")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                if isDirty {
                    Button("revert") {
                        revertChanges()
                    }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                    
                    Button("save_changes") {
                        save()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("s", modifiers: .command)
                } else {
                    if isActive {
                        Label("using_current", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        Button("use_this_vendor") {
                            try? ConfigManager.shared.switchToVendor(with: vendor.id)
                        }
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .onChange(of: isDirty) { _, newValue in
                isDirtyBinding = newValue
            }
            
            Divider()
            
            // Form Content
            Form {
                Section("basic_info") {
                    TextField("name_label", text: $name)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("base_url_label", text: $baseURL)
                            .textContentType(.URL)
                        
                        if let error = validationErrors["baseURL"] {
                            Text(LocalizedStringKey(error))
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section("auth_section") {
                    HStack {
                        ZStack(alignment: .trailing) {
                            if showToken {
                                TextField("auth_token_label", text: $authToken)
                            } else {
                                SecureField("auth_token_label", text: $authToken)
                            }
                        }
                        
                        // Copy Button
                        if showToken {
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(authToken, forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("copy_token")
                            .padding(.trailing, 4)
                        }
                        
                        // Toggle Visibility Button
                        Button {
                            showToken.toggle()
                        } label: {
                            Image(systemName: showToken ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("token_visible_hint")
                    }
                    
                    Text("auth_token_helper")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("models_section") {
                    TextField("default_model_label", text: $defaultModel)
                    
                    DisclosureGroup("model_mapping", isExpanded: $showAdvancedModels) {
                        TextField("opus_model_label", text: $opusModel)
                        TextField("sonnet_model_label", text: $sonnetModel)
                        TextField("haiku_model_label", text: $haikuModel)
                        TextField("small_fast_model_label", text: $smallFastModel)
                    }
                }
                
                Section("connection_section") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("timeout_label", text: $timeout)
                        if let error = validationErrors["timeout"] {
                             Text(LocalizedStringKey(error))
                                 .font(.caption)
                                 .foregroundColor(.red)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Footer (Test Connection)
            HStack {
                Button(action: testConnection) {
                    if isTesting {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal, 4)
                    } else {
                        Label("test_connection", systemImage: "network")
                    }
                }
                .disabled(isTesting || baseURL.isEmpty)
                
                if let result = testResult {
                    if result {
                        Label("connection_success", systemImage: "checkmark")
                            .foregroundColor(.green)
                    } else {
                        Label(testMessage ?? "Failed", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onAppear {
            validate(quiet: true)
        }
    }
    
    // MARK: - Logic
    
    private func revertChanges() {
        name = originalVendor.name
        let env = originalVendor.env
        baseURL = env["ANTHROPIC_BASE_URL"] ?? env["NTHROPIC_BASE_URL"] ?? ""
        authToken = env["ANTHROPIC_AUTH_TOKEN"] ?? ""
        timeout = env["API_TIMEOUT_MS"] ?? ""
        defaultModel = env["ANTHROPIC_MODEL"] ?? ""
        opusModel = env["ANTHROPIC_DEFAULT_OPUS_MODEL"] ?? ""
        sonnetModel = env["ANTHROPIC_DEFAULT_SONNET_MODEL"] ?? ""
        haikuModel = env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] ?? ""
        smallFastModel = env["ANTHROPIC_SMALL_FAST_MODEL"] ?? ""
        
        validationErrors.removeAll()
    }
    
    @discardableResult
    private func validate(quiet: Bool = false) -> Bool {
        var errors: [String: String] = [:]
        
        if name.isEmpty {
            errors["name"] = "validation_name_required"
        }
        
        if !baseURL.isEmpty {
            if !baseURL.lowercased().hasPrefix("http://") && !baseURL.lowercased().hasPrefix("https://") {
                errors["baseURL"] = "validation_url_invalid"
            }
        }
        
        if !timeout.isEmpty {
             if let val = Int(timeout), val >= 1000, val <= 300000 {
                 // ok
             } else {
                 errors["timeout"] = "validation_timeout_range"
             }
        }
        
        if !quiet {
            self.validationErrors = errors
        }
        return errors.isEmpty
    }

    private func save() {
        guard validate() else { return }
        
        var env: [String: String] = originalVendor.env
        
        func update(_ key: String, _ value: String) {
            if value.trimmingCharacters(in: .whitespaces).isEmpty {
                env.removeValue(forKey: key)
            } else {
                env[key] = value.trimmingCharacters(in: .whitespaces)
            }
        }
        
        update("ANTHROPIC_BASE_URL", baseURL)
        update("NTHROPIC_BASE_URL", baseURL) 
        update("ANTHROPIC_AUTH_TOKEN", authToken)
        update("API_TIMEOUT_MS", timeout)
        update("ANTHROPIC_MODEL", defaultModel)
        update("ANTHROPIC_DEFAULT_OPUS_MODEL", opusModel)
        update("ANTHROPIC_DEFAULT_SONNET_MODEL", sonnetModel)
        update("ANTHROPIC_DEFAULT_HAIKU_MODEL", haikuModel)
        update("ANTHROPIC_SMALL_FAST_MODEL", smallFastModel)
        
        let updatedVendor = Vendor(id: vendor.id, name: name, env: env)
        onSave(updatedVendor)
        originalVendor = updatedVendor
    }
    
    private func testConnection() {
        guard let url = URL(string: baseURL) else { return }
        
        isTesting = true
        testResult = nil
        testMessage = nil
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET" 
        if url.path.isEmpty || url.path == "/" {
            request.url = url.appendingPathComponent("v1/models")
        }
        
        request.timeoutInterval = 5
        if !authToken.isEmpty {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.setValue(authToken, forHTTPHeaderField: "x-api-key")
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isTesting = false
                if let error = error {
                    testResult = false
                    testMessage = error.localizedDescription
                } else if let httpResponse = response as? HTTPURLResponse {
                    if (200...299).contains(httpResponse.statusCode) {
                        testResult = true
                    } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                         testResult = false
                         testMessage = "Auth Failed (\(httpResponse.statusCode))"
                    } else {
                        testResult = false
                        testMessage = "Error: \(httpResponse.statusCode)"
                    }
                }
            }
        }.resume()
    }
}
