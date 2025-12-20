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
            // Header
            HStack {
                Text(vendor == nil ? "add_vendor" : "edit_vendor")
                    .font(DesignSystem.Fonts.title)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
            }
            .padding(DesignSystem.Spacing.large)
            .background(DesignSystem.Colors.surface)
            
            Divider()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    // 1. Basic Info Section
                    ModernSection(title: "basic_info") {
                        VStack(spacing: 0) {
                            EditRow(label: "id_label", text: $id, placeholder: "unique_id_placeholder", disabled: vendor != nil)
                            ModernDivider()
                            EditRow(label: "name_label", text: $name, placeholder: "display_name_placeholder")
                        }
                    }

                    // 2. Connection Section
                    ModernSection(title: "connection_section") {
                        VStack(spacing: 0) {
                            EditRow(
                                label: "base_url_label",
                                text: $baseURL,
                                placeholder: "base_url_placeholder",
                                helperText: "base_url_helper",
                                error: errors["baseURL"]
                            )
                            ModernDivider()
                            EditRow(
                                label: "timeout_label",
                                text: $timeout,
                                placeholder: "timeout_placeholder",
                                helperText: "timeout_helper",
                                error: errors["timeout"]
                            ) {
                                Menu {
                                    Button("10s (10000)") { timeout = "10000" }
                                    Button("30s (30000)") { timeout = "30000" }
                                    Button("60s (60000)") { timeout = "60000" }
                                } label: {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                .menuStyle(.borderlessButton)
                                .help("quick_set")
                            }
                        }
                    }

                    // 3. Auth Section
                    ModernSection(title: "auth_section") {
                        VStack(spacing: 0) {
                            EditRow(
                                label: "auth_token_label",
                                text: $authToken,
                                placeholder: "auth_token_placeholder",
                                helperText: "auth_token_helper",
                                isSecure: true,
                                error: errors["authToken"]
                            )
                        }
                    }

                    // 4. Models Section
                    ModernSection(title: "models_section") {
                        VStack(spacing: 0) {
                            EditRow(label: "default_model_label", text: $defaultModel, placeholder: "claude-3-5-sonnet-...", helperText: "ANTHROPIC_MODEL")
                            
                            if showMoreModels {
                                ModernDivider()
                                EditRow(label: "opus_model_label", text: $opusModel, helperText: "ANTHROPIC_DEFAULT_OPUS_MODEL")
                                ModernDivider()
                                EditRow(label: "sonnet_model_label", text: $sonnetModel, helperText: "ANTHROPIC_DEFAULT_SONNET_MODEL")
                                ModernDivider()
                                EditRow(label: "haiku_model_label", text: $haikuModel, helperText: "ANTHROPIC_DEFAULT_HAIKU_MODEL")
                                ModernDivider()
                                EditRow(label: "small_fast_model_label", text: $smallFastModel, helperText: "ANTHROPIC_SMALL_FAST_MODEL")
                            }
                            
                            ModernDivider()
                            Button(action: { withAnimation { showMoreModels.toggle() } }) {
                                HStack {
                                    Text(showMoreModels ? "less" : "more")
                                    Image(systemName: showMoreModels ? "chevron.up" : "chevron.down")
                                }
                                .font(DesignSystem.Fonts.caption)
                                .foregroundColor(DesignSystem.Colors.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(DesignSystem.Spacing.large)
            }

            Divider()

            // Footer
            HStack(spacing: DesignSystem.Spacing.medium) {
                Spacer()
                Button("cancel") { onCancel() }
                    .buttonStyle(SecondaryButtonStyle())
                    .keyboardShortcut(.escape)
                
                Button("save") { save() }
                    .buttonStyle(PrimaryButtonStyle())
                    .keyboardShortcut(.return)
                    .disabled(!isValid)
            }
            .padding(DesignSystem.Spacing.large)
            .background(DesignSystem.Colors.surface)
        }
        .frame(width: 500, height: 750)
        .background(DesignSystem.Colors.background)
        .onAppear { loadData() }
        .onChange(of: baseURL) { _ in validate() }
        .onChange(of: timeout) { _ in validate() }
        .onChange(of: authToken) { _ in validate() }
    }

    // MARK: - Logic

    private var isValid: Bool {
        validate()
        return errors.isEmpty && !id.isEmpty && !name.isEmpty
    }

    private func validate() {
        var newErrors: [String: String] = [:]

        // Base URL Validation
        if !baseURL.isEmpty {
            if !baseURL.lowercased().hasPrefix("http://") && !baseURL.lowercased().hasPrefix("https://") {
                newErrors["baseURL"] = "validation_base_url"
            }
        }

        // Timeout Validation
        if !timeout.isEmpty {
            if let val = Int(timeout) {
                if val < 1000 || val > 300000 {
                    newErrors["timeout"] = "validation_timeout_range"
                }
            } else {
                newErrors["timeout"] = "validation_timeout_number"
            }
        }

        // Auth Token Validation
        if !authToken.isEmpty && authToken.count < 10 {
            newErrors["authToken"] = "validation_token_length"
        }

        self.errors = newErrors
    }

    private func loadData() {
        guard let v = vendor else {
            // Default ID/Name if new
            id = UUID().uuidString.prefix(8).lowercased()
            return
        }
        
        id = v.id
        name = v.name
        let env = v.env
        
        // Load Env Vars
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
        
        // We removed explicit provider selection, but we can default to anthropic 
        // or just let the environment variables dictate the behavior (Claude Code defaults to anthropic)
        // If we really need to set it:
        // env["provider"] = "anthropic" 
        // But better to not force it if we want to be generic.
        // However, existing logic might rely on it. I'll set it if it was there, or leave it.
        // The user explicitly asked to "Remove 'Provider' selection". 
        // I will NOT set `provider` key specifically unless it's critical. 
        // Looking at previous code, it was set. I'll preserve existing provider if editing, or default if new?
        // Actually, safer to just NOT touch "provider" key if I'm not editing it.
        // But if I create a NEW vendor, I should probably set a default?
        // Let's assume generic "anthropic" is fine if missing.
        if vendor == nil {
             env["provider"] = "anthropic"
        }
        
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

struct EditRow<Accessory: View>: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var helperText: String? = nil
    var isSecure: Bool = false
    var disabled: Bool = false
    var error: String? = nil
    @ViewBuilder var accessory: () -> Accessory
    
    @State private var isVisible: Bool = false

    init(label: String, text: Binding<String>, placeholder: String = "", helperText: String? = nil, isSecure: Bool = false, disabled: Bool = false, error: String? = nil, @ViewBuilder accessory: @escaping () -> Accessory) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.helperText = helperText
        self.isSecure = isSecure
        self.disabled = disabled
        self.error = error
        self.accessory = accessory
    }

    init(label: String, text: Binding<String>, placeholder: String = "", helperText: String? = nil, isSecure: Bool = false, disabled: Bool = false, error: String? = nil) where Accessory == EmptyView {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.helperText = helperText
        self.isSecure = isSecure
        self.disabled = disabled
        self.error = error
        self.accessory = { EmptyView() }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.medium) {
            Text(LocalizedStringKey(label))
                .font(DesignSystem.Fonts.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .frame(width: 120, alignment: .leading)
                .padding(.top, 4) // Align with text field
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if isSecure && !isVisible {
                        SecureField(LocalizedStringKey(placeholder), text: $text)
                            .textFieldStyle(.plain)
                    } else {
                        TextField(LocalizedStringKey(placeholder), text: $text)
                            .textFieldStyle(.plain)
                    }
                    
                    if isSecure {
                        Button(action: { isVisible.toggle() }) {
                            Image(systemName: isVisible ? "eye.slash" : "eye")
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    accessory()
                }
                .padding(8)
                .background(DesignSystem.Colors.background)
                .cornerRadius(DesignSystem.CornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .stroke(error != nil ? DesignSystem.Colors.error : DesignSystem.Colors.border, lineWidth: 1)
                )
                
                if let error = error {
                    Text(LocalizedStringKey(error))
                        .font(DesignSystem.Fonts.caption)
                        .foregroundColor(DesignSystem.Colors.error)
                } else if let helper = helperText {
                    Text(LocalizedStringKey(helper))
                        .font(DesignSystem.Fonts.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .opacity(disabled ? 0.6 : 1.0)
        .disabled(disabled)
    }
}