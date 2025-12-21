import SwiftUI

struct VendorEditView: View {
    let vendor: Vendor?
    let onSave: (Vendor) -> Void
    let onCancel: () -> Void

    // Basic Info
    @State private var id: String = ""
    @State private var name: String = ""
    
    // Connection
    @State private var baseURL: String = ""
    @State private var timeout: String = ""

    // Auth
    @State private var authToken: String = ""

    // Models
    @State private var defaultModel: String = ""
    @State private var opusModel: String = ""
    @State private var sonnetModel: String = ""
    @State private var haikuModel: String = ""
    @State private var smallFastModel: String = ""
    @State private var showMoreModels: Bool = false

    // Validation State
    @State private var errors: [String: String] = [:]

    var body: some View {
        VStack(spacing: 0) {
            Text(vendor == nil ? "add_vendor" : "edit_vendor")
                .font(.headline)
                .padding()
            
            Form {
                Section(header: Text("basic_info")) {
                    TextField("id_label", text: $id)
                        .disabled(vendor != nil)
                    TextField("name_label", text: $name)
                }

                Section(header: Text("connection_section")) {
                    TextField("base_url_label", text: $baseURL)
                    if let error = errors["baseURL"] {
                        Text(LocalizedStringKey(error)).foregroundColor(.red).font(.caption)
                    }
                    
                    HStack {
                        TextField("timeout_label", text: $timeout)
                        Menu {
                            Button("10s (10000)") { timeout = "10000" }
                            Button("30s (30000)") { timeout = "30000" }
                            Button("60s (60000)") { timeout = "60000" }
                        } label: {
                            Image(systemName: "bolt.fill")
                        }
                        .menuStyle(.borderlessButton)
                    }
                    if let error = errors["timeout"] {
                         Text(LocalizedStringKey(error)).foregroundColor(.red).font(.caption)
                    }
                }

                Section(header: Text("auth_section")) {
                    SecureField("auth_token_label", text: $authToken)
                    if let error = errors["authToken"] {
                         Text(LocalizedStringKey(error)).foregroundColor(.red).font(.caption)
                    }
                }

                Section(header: Text("models_section")) {
                    TextField("default_model_label", text: $defaultModel)
                    
                    if showMoreModels {
                        TextField("opus_model_label", text: $opusModel)
                        TextField("sonnet_model_label", text: $sonnetModel)
                        TextField("haiku_model_label", text: $haikuModel)
                        TextField("small_fast_model_label", text: $smallFastModel)
                    }
                    
                    Button(showMoreModels ? "less" : "more") {
                        withAnimation { showMoreModels.toggle() }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("cancel") { onCancel() }
                    .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("save") { save() }
                    .keyboardShortcut(.return)
                    .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
        .onAppear { loadData() }
        .onChange(of: baseURL) { _, _ in validate() }
        .onChange(of: timeout) { _, _ in validate() }
        .onChange(of: authToken) { _, _ in validate() }
    }

    // MARK: - Logic

    private var isValid: Bool {
        validate()
        return errors.isEmpty && !id.isEmpty && !name.isEmpty
    }

    private func validate() {
        var newErrors: [String: String] = [:]

        if !baseURL.isEmpty {
            if !baseURL.lowercased().hasPrefix("http://") && !baseURL.lowercased().hasPrefix("https://") {
                newErrors["baseURL"] = "validation_base_url"
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

        if !authToken.isEmpty && authToken.count < 10 {
            newErrors["authToken"] = "validation_token_length"
        }

        self.errors = newErrors
    }

    private func loadData() {
        guard let v = vendor else {
            id = UUID().uuidString.prefix(8).lowercased()
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
    }

    private func save() {
        var env: [String: String] = vendor?.env ?? [:]
        
        func setOrRemove(_ key: String, _ value: String) {
            if value.trimmingCharacters(in: .whitespaces).isEmpty {
                env.removeValue(forKey: key)
            } else {
                env[key] = value.trimmingCharacters(in: .whitespaces)
            }
        }
        
        setOrRemove("NTHROPIC_BASE_URL", baseURL)
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
