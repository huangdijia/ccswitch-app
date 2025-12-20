import SwiftUI

struct VendorEditView: View {
    let vendor: Vendor?
    let onSave: (Vendor) -> Void
    let onCancel: () -> Void

    @State private var id: String = ""
    @State private var displayName: String = ""
    @State private var provider: String = "anthropic"
    @State private var model: String = ""
    @State private var apiKeyEnv: String = ""
    @State private var baseURL: String = ""
    @State private var notes: String = ""
    @State private var useCustomBaseURL: Bool = false
    @State private var existingEnv: [String: String] = [:] // Store original env to prevent data loss

    // Constants for autocomplete
    private let commonProviders = ["anthropic", "deepseek", "openai"]
    private let commonModels = ["claude-3-5-sonnet", "deepseek-chat", "gpt-4o"]
    private let commonApiKeys = ["ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "DEEPSEEK_API_KEY", "OPENAI_API_KEY"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(vendor == nil ? "add_vendor" : "edit_vendor")
                .font(.headline)

            Form {
                Section(header: Text("基本信息")) {
                    HStack {
                        Text("ID：")
                        TextField("唯一标识", text: $id)
                            .disabled(vendor != nil)
                    }

                    HStack {
                        Text("显示名称：")
                        TextField("供应商名称", text: $displayName)
                    }
                }

                Section(header: Text("Claude 配置")) {
                    Picker("Provider：", selection: $provider) {
                        ForEach(commonProviders, id: \.self) { p in
                            Text(p).tag(p)
                        }
                        Text("Custom").tag("")
                    }
                    .pickerStyle(.menu)
                    // If user wants custom provider not in list, they can edit text field?
                    // Picker binds to selection. If selection is not in list, it might be tricky.
                    // Better pattern: ComboBox or Menu + TextField.
                    // For simplicity, let's keep TextField but add a Menu for quick selection.
                    
                    HStack {
                        Text("Provider (Custom)：")
                        TextField("provider", text: $provider)
                    }
                    
                    HStack {
                        Text("Model：")
                        TextField("model", text: $model)
                        Menu {
                            ForEach(commonModels, id: \.self) { m in
                                Button(m) { model = m }
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 20)
                    }

                    HStack {
                        Text("API Key Env：")
                        TextField("api_key_env_label", text: $apiKeyEnv)
                        Menu {
                            ForEach(commonApiKeys, id: \.self) { key in
                                Button(key) { apiKeyEnv = key }
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 20)
                    }

                    Toggle("自定义 Base URL", isOn: $useCustomBaseURL)

                    if useCustomBaseURL {
                        HStack {
                            Text("Base URL：")
                            TextField("base_url_label", text: $baseURL)
                        }
                    }
                }

                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }

            HStack {
                Spacer()

                Button("cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape)

                Button("save") {
                    save()
                }
                .keyboardShortcut(.return)
                .disabled(id.isEmpty || displayName.isEmpty || provider.isEmpty || model.isEmpty || apiKeyEnv.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 600)
        .onAppear {
            loadVendorData()
        }
    }

    private func loadVendorData() {
        if let vendor = vendor {
            id = vendor.id
            displayName = vendor.name
            existingEnv = vendor.env
            
            provider = vendor.env["provider"] ?? vendor.env["type"] ?? "anthropic"
            model = vendor.env["model"] ?? vendor.env["ANTHROPIC_MODEL"] ?? ""
            apiKeyEnv = vendor.env["apiKeyEnv"] ?? vendor.env["api_key_env"] ?? vendor.env["ANTHROPIC_AUTH_TOKEN"] ?? ""
            
            if let url = vendor.env["baseURL"] ?? vendor.env["ANTHROPIC_BASE_URL"] {
                baseURL = url
                useCustomBaseURL = true
            } else {
                useCustomBaseURL = false
            }
            
            notes = vendor.notes ?? ""
        } else {
            // Defaults for new vendor
            provider = "anthropic"
            model = "claude-3-5-sonnet"
            apiKeyEnv = "ANTHROPIC_API_KEY"
        }
    }

    private func save() {
        var env = existingEnv
        env["provider"] = provider
        env["model"] = model
        env["apiKeyEnv"] = apiKeyEnv
        
        // Handle common variations for legacy compatibility if needed, 
        // but new format prefers 'provider', 'model', 'apiKeyEnv', 'baseURL'.
        // We will stick to the standard keys for new edits.
        
        if useCustomBaseURL {
            env["baseURL"] = baseURL
        } else {
            env.removeValue(forKey: "baseURL")
            env.removeValue(forKey: "ANTHROPIC_BASE_URL")
        }

        let newVendor = Vendor(
            id: id,
            name: displayName,
            env: env,
            notes: notes.isEmpty ? nil : notes
        )

        onSave(newVendor)
    }
}