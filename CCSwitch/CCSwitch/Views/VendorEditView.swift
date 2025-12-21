import SwiftUI

struct VendorEditView: View {
    let vendor: Vendor?
    let onSave: (Vendor) -> Void
    let onCancel: () -> Void

    // Form State
    @State private var id: String = ""
    @State private var name: String = ""
    @State private var preset: VendorPreset = .custom
    
    @State private var baseURL: String = ""
    @State private var authToken: String = ""
    @State private var showToken: Bool = false
    
    @State private var defaultModel: String = ""
    @State private var opusModel: String = ""
    @State private var sonnetModel: String = ""
    @State private var haikuModel: String = ""
    @State private var smallFastModel: String = ""
    @State private var isAdvancedModelsExpanded: Bool = false
    
    @State private var timeout: String = ""
    
    // Validation State
    @State private var errors: [String: String] = [:]

    var body: some View {
        VStack(spacing: 0) {
            // Header (Custom for Sheet)
            ZStack {
                Text(vendor == nil ? "add_new_vendor" : "edit_vendor")
                    .font(.headline)
                
                HStack {
                    Button("cancel") { onCancel() }
                        .keyboardShortcut(.escape)
                        .controlSize(.small)
                    Spacer()
                    Button("save") { save() }
                        .keyboardShortcut(.return)
                        .disabled(!isValid)
                        .controlSize(.small)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()

            Form {
                // MARK: - Section 1: Basic Info
                Section {
                    TextField("name_label", text: $name)
                        .onChange(of: name) { _, _ in validate() }
                    
                    if vendor == nil { // Only show preset for new vendors
                        Picker("preset_label", selection: $preset) {
                            Text("preset_custom").tag(VendorPreset.custom)
                            Text("preset_anthropic").tag(VendorPreset.anthropic)
                            Text("preset_openai").tag(VendorPreset.openai)
                        }
                        .onChange(of: preset) { _, newValue in
                            applyPreset(newValue)
                        }
                    }
                } header: {
                    Text("basic_info")
                }

                // MARK: - Section 2: Connection & Auth
                Section {
                    TextField("base_url_label", text: $baseURL)
                        .textContentType(.URL)
                        .onChange(of: baseURL) { _, _ in validate() }
                    
                    if let error = errors["baseURL"] {
                        Text(LocalizedStringKey(error))
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    HStack {
                        ZStack(alignment: .trailing) {
                            if showToken {
                                TextField("auth_token_label", text: $authToken)
                            } else {
                                SecureField("auth_token_label", text: $authToken)
                            }
                        }
                        
                        Button(action: { showToken.toggle() }) {
                            Image(systemName: showToken ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Toggle visibility")
                    }
                    Text("auth_token_hint")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let error = errors["authToken"] {
                         Text(LocalizedStringKey(error))
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    // Test Connection
                    TestConnectionView(url: baseURL, token: authToken)
                        .padding(.top, 4)
                    
                } header: {
                    Text("connection_and_auth")
                }

                // MARK: - Section 3: Models
                Section {
                    TextField("default_model_label", text: $defaultModel)
                    
                    DisclosureGroup("advanced_model_mapping", isExpanded: $isAdvancedModelsExpanded) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("advanced_model_mapping_desc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("opus_model_label", text: $opusModel)
                            TextField("sonnet_model_label", text: $sonnetModel)
                            TextField("haiku_model_label", text: $haikuModel)
                            TextField("small_fast_model_label", text: $smallFastModel)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("models_section")
                }

                // MARK: - Section 4: Network
                Section {
                    TextField("timeout_label", text: $timeout)
                        .onChange(of: timeout) { _, _ in validate() }
                    if let error = errors["timeout"] {
                         Text(LocalizedStringKey(error))
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("network_settings")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 600)
        .onAppear { loadData() }
    }

    // MARK: - Logic

    private var isValid: Bool {
        // Simple check for UI enabling, full validation happens in validate()
        return !name.isEmpty && 
               !baseURL.isEmpty && 
               (baseURL.lowercased().hasPrefix("http://") || baseURL.lowercased().hasPrefix("https://")) &&
               errors.isEmpty
    }

    private func validate() {
        var newErrors: [String: String] = [:]

        if name.isEmpty {
            newErrors["name"] = "validation_name_required"
        }

        if !baseURL.isEmpty {
            if !baseURL.lowercased().hasPrefix("http://") && !baseURL.lowercased().hasPrefix("https://") {
                newErrors["baseURL"] = "validation_url_invalid"
            }
        }

        if !timeout.isEmpty {
            if let val = Int(timeout) {
                if val < 1000 || val > 300000 {
                    newErrors["timeout"] = "validation_timeout_range"
                }
            } else {
                newErrors["timeout"] = "validation_timeout_number"
            }
        }
        
        // Removed strict token validation to allow empty (env var usage)

        self.errors = newErrors
    }

    private func loadData() {
        guard let v = vendor else {
            id = UUID().uuidString.prefix(8).lowercased()
            // Default preset settings
            applyPreset(.custom)
            return
        }
        
        id = v.id
        name = v.name
        let env = v.env
        
        baseURL = env["ANTHROPIC_BASE_URL"] ?? env["NTHROPIC_BASE_URL"] ?? env["baseURL"] ?? ""
        authToken = env["ANTHROPIC_AUTH_TOKEN"] ?? env["apiKeyEnv"] ?? ""
        defaultModel = env["ANTHROPIC_MODEL"] ?? env["model"] ?? ""
        timeout = env["API_TIMEOUT_MS"] ?? ""
        opusModel = env["ANTHROPIC_DEFAULT_OPUS_MODEL"] ?? ""
        sonnetModel = env["ANTHROPIC_DEFAULT_SONNET_MODEL"] ?? ""
        haikuModel = env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] ?? ""
        smallFastModel = env["ANTHROPIC_SMALL_FAST_MODEL"] ?? ""
        
        // Heuristic to detect preset? Not strictly needed for edit
    }
    
    private func applyPreset(_ preset: VendorPreset) {
        switch preset {
        case .anthropic:
            baseURL = "https://api.anthropic.com"
            defaultModel = "claude-3-5-sonnet-20240620"
        case .openai:
            baseURL = "https://api.openai.com/v1"
            defaultModel = "gpt-4o"
        case .custom:
            // Keep existing or clear if strictly needed, but better to leave as is for user adjustment
            if baseURL.isEmpty { baseURL = "" }
        }
    }

    private func save() {
        validate()
        guard errors.isEmpty else { return }
        
        var env: [String: String] = vendor?.env ?? [:]
        
        func setOrRemove(_ key: String, _ value: String) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                env.removeValue(forKey: key)
            } else {
                env[key] = trimmed
            }
        }
        
        setOrRemove("NTHROPIC_BASE_URL", baseURL) // Legacy
        if !baseURL.isEmpty {
             env["ANTHROPIC_BASE_URL"] = baseURL
        }
        
        setOrRemove("ANTHROPIC_AUTH_TOKEN", authToken)
        setOrRemove("API_TIMEOUT_MS", timeout)
        
        setOrRemove("ANTHROPIC_MODEL", defaultModel)
        setOrRemove("ANTHROPIC_DEFAULT_OPUS_MODEL", opusModel)
        setOrRemove("ANTHROPIC_DEFAULT_SONNET_MODEL", sonnetModel)
        setOrRemove("ANTHROPIC_DEFAULT_HAIKU_MODEL", haikuModel)
        setOrRemove("ANTHROPIC_SMALL_FAST_MODEL", smallFastModel)
        
        let newVendor = Vendor(id: id, name: name, env: env)
        onSave(newVendor)
    }
}

// MARK: - Helper Enums
enum VendorPreset {
    case custom
    case anthropic
    case openai
}

// MARK: - Test Connection View component
struct TestConnectionView: View {
    let url: String
    let token: String
    
    @State private var isTesting = false
    @State private var status: ConnectionStatus = .idle
    @State private var errorMessage: String?
    
    enum ConnectionStatus {
        case idle
        case success
        case failure
    }
    
    var body: some View {
        HStack {
            Button(action: runTest) {
                if isTesting {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                } else {
                    Label("test_connection_btn", systemImage: "network")
                }
            }
            .buttonStyle(.bordered)
            .disabled(url.isEmpty || isTesting)
            
            Spacer()
            
            if status == .success {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("status_success")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .transition(.opacity)
            } else if status == .failure {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(LocalizedStringKey(errorMessage ?? "status_network_error"))
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
                .transition(.opacity)
            }
        }
    }
    
    private func runTest() {
        guard let urlObj = URL(string: url) else { return }
        
        isTesting = true
        status = .idle
        errorMessage = nil
        
        var request = URLRequest(url: urlObj)
        // Heuristic: Append /v1/models if root URL is provided for common APIs
        if urlObj.path == "" || urlObj.path == "/" {
             request.url = urlObj.appendingPathComponent("v1/models")
        }
        
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue(token, forHTTPHeaderField: "x-api-key") // Anthropic specific
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isTesting = false
                
                if let _ = error {
                    // Distinguish strictly network error vs auth error if possible, 
                    // but for now generic network error
                    status = .failure
                    errorMessage = "status_network_error"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if (200...299).contains(httpResponse.statusCode) {
                        status = .success
                        // Auto-fade out success after 3s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { status = .idle }
                        }
                    } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        status = .failure
                        errorMessage = "status_auth_failed"
                    } else {
                        status = .failure
                        errorMessage = "Error: \(httpResponse.statusCode)"
                    }
                }
            }
        }.resume()
    }
}