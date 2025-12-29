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
                Text(LocalizedStringKey(vendor == nil ? LocalizationKey.addNewVendor : LocalizationKey.editVendor))
                    .font(.headline)

                HStack {
                    Button(LocalizedStringKey(LocalizationKey.cancel)) { onCancel() }
                        .keyboardShortcut(.escape)
                        .controlSize(.small)
                    Spacer()
                    Button(LocalizedStringKey(LocalizationKey.save)) { save() }
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
                    TextField(LocalizedStringKey(LocalizationKey.nameLabel), text: $name)
                        .onChange(of: name) { _, _ in validate() }

                    if vendor == nil { // Only show preset for new vendors
                        Picker(LocalizedStringKey(LocalizationKey.presetLabel), selection: $preset) {
                            Text(LocalizedStringKey(LocalizationKey.presetCustom)).tag(VendorPreset.custom)
                            Text(LocalizedStringKey(LocalizationKey.presetAnthropic)).tag(VendorPreset.anthropic)
                            Text(LocalizedStringKey(LocalizationKey.presetOpenAI)).tag(VendorPreset.openai)
                        }
                        .onChange(of: preset) { _, newValue in
                            applyPreset(newValue)
                        }
                    }
                } header: {
                    Text(LocalizedStringKey(LocalizationKey.basicInfo))
                }

                // MARK: - Section 2: Connection & Auth
                Section {
                    LabeledContent(LocalizedStringKey(LocalizationKey.baseURLLabel)) {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField(LocalizedStringKey(LocalizationKey.baseURLLabel), text: $baseURL)
                                .labelsHidden()
                                .textContentType(.URL)
                                .onChange(of: baseURL) { _, _ in validate() }

                            if let error = errors["baseURL"] {
                                Text(LocalizedStringKey(error))
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    LabeledContent(LocalizedStringKey(LocalizationKey.authTokenLabel)) {
                        HStack {
                            ZStack(alignment: .trailing) {
                                if showToken {
                                    TextField(LocalizedStringKey(LocalizationKey.authTokenLabel), text: $authToken)
                                        .labelsHidden()
                                } else {
                                    SecureField(LocalizedStringKey(LocalizationKey.authTokenLabel), text: $authToken)
                                        .labelsHidden()
                                }
                            }

                            Button(action: { showToken.toggle() }) {
                                Image(systemName: showToken ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Toggle visibility")
                        }
                    }
                    Text(LocalizedStringKey(LocalizationKey.authTokenHint))
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
                    Text(LocalizedStringKey(LocalizationKey.connectionAndAuth))
                }

                // MARK: - Section 3: Models
                Section {
                    TextField(LocalizedStringKey(LocalizationKey.defaultModelLabel), text: $defaultModel)

                    DisclosureGroup(LocalizedStringKey(LocalizationKey.modelMapping), isExpanded: $isAdvancedModelsExpanded) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedStringKey(LocalizationKey.advancedModelMappingDesc))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField(LocalizedStringKey(LocalizationKey.opusModelLabel), text: $opusModel)
                            TextField(LocalizedStringKey(LocalizationKey.sonnetModelLabel), text: $sonnetModel)
                            TextField(LocalizedStringKey(LocalizationKey.haikuModelLabel), text: $haikuModel)
                            TextField(LocalizedStringKey(LocalizationKey.smallFastModelLabel), text: $smallFastModel)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(LocalizedStringKey(LocalizationKey.modelsSection))
                }

                // MARK: - Section 4: Network
                Section {
                    LabeledContent(LocalizedStringKey(LocalizationKey.timeoutLabel)) {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField(LocalizedStringKey(LocalizationKey.timeoutLabel), text: $timeout)
                                .labelsHidden()
                                .onChange(of: timeout) { _, _ in validate() }
                            if let error = errors["timeout"] {
                                 Text(LocalizedStringKey(error))
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } header: {
                    Text(LocalizedStringKey(LocalizationKey.networkSettings))
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
            newErrors["name"] = LocalizationKey.validationNameRequired
        }

        if !baseURL.isEmpty {
            if !baseURL.lowercased().hasPrefix("http://") && !baseURL.lowercased().hasPrefix("https://") {
                newErrors["baseURL"] = LocalizationKey.validationURLInvalid
            }
        }

        if !timeout.isEmpty {
            if let val = Int(timeout) {
                if val < 1000 || val > 300000 {
                    newErrors["timeout"] = LocalizationKey.validationTimeoutRange
                }
            } else {
                newErrors["timeout"] = LocalizationKey.validationTimeoutNumber
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
        
        baseURL = env["ANTHROPIC_BASE_URL"] ?? ""
        authToken = env["ANTHROPIC_AUTH_TOKEN"] ?? ""
        defaultModel = env["ANTHROPIC_MODEL"] ?? ""
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
        
        setOrRemove("ANTHROPIC_BASE_URL", baseURL)
        
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
                    Label(LocalizedStringKey(LocalizationKey.testConnectionBtn), systemImage: "network")
                }
            }
            .buttonStyle(.bordered)
            .disabled(url.isEmpty || isTesting)

            Spacer()

            if status == .success {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(LocalizedStringKey(LocalizationKey.statusSuccess))
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .transition(.opacity)
            } else if status == .failure {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage ?? LocalizationKey.localized(LocalizationKey.statusNetworkError))
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
                    errorMessage = LocalizationKey.localized(LocalizationKey.statusNetworkError)
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
                        errorMessage = LocalizationKey.localized(LocalizationKey.statusAuthFailed)
                    } else {
                        status = .failure
                        errorMessage = LocalizationKey.localized(LocalizationKey.connectionErrorStatus, String(httpResponse.statusCode))
                    }
                }
            }
        }.resume()
    }
}