import SwiftUI

/// Detail view for editing a single vendor
struct VendorDetailView: View {
    let vendor: Vendor
    let isActive: Bool
    @Binding var isDirtyBinding: Bool
    let onSave: (Vendor) -> Void
    let onSwitchVendor: (String) -> Void

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
    @State private var showAdvancedModels = false
    @State private var showToken = false
    @State private var validationErrors: [String: String] = [:]
    @State private var isTesting = false
    @State private var testResult: Bool?
    @State private var testMessage: String?

    init(
        vendor: Vendor,
        isActive: Bool,
        isDirtyBinding: Binding<Bool>,
        onSave: @escaping (Vendor) -> Void,
        onSwitchVendor: @escaping (String) -> Void
    ) {
        self.vendor = vendor
        self.isActive = isActive
        self._isDirtyBinding = isDirtyBinding
        self.onSave = onSave
        self.onSwitchVendor = onSwitchVendor
        _originalVendor = State(initialValue: vendor)
        _name = State(initialValue: vendor.name)
        let env = vendor.env
        _baseURL = State(initialValue: env["ANTHROPIC_BASE_URL"] ?? "")
        _authToken = State(initialValue: env["ANTHROPIC_AUTH_TOKEN"] ?? "")
        _timeout = State(initialValue: env["API_TIMEOUT_MS"] ?? "")
        _defaultModel = State(initialValue: env["ANTHROPIC_MODEL"] ?? "")
        _opusModel = State(initialValue: env["ANTHROPIC_DEFAULT_OPUS_MODEL"] ?? "")
        _sonnetModel = State(initialValue: env["ANTHROPIC_DEFAULT_SONNET_MODEL"] ?? "")
        _haikuModel = State(initialValue: env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] ?? "")
        _smallFastModel = State(initialValue: env["ANTHROPIC_SMALL_FAST_MODEL"] ?? "")
    }

    private var isDirty: Bool {
        name != originalVendor.name ||
        baseURL != (originalVendor.env["ANTHROPIC_BASE_URL"] ?? "") ||
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
            headerView

            Divider()

            // Form
            formView

            Divider()

            // Footer
            footerView
        }
        .onAppear { validate(quiet: true) }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(name.isEmpty ? LocalizationKey.untitledVendor : name))
                    .font(.title2)
                    .fontWeight(.bold)
                if isDirty {
                    Text(LocalizedStringKey(LocalizationKey.unsavedChanges))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            Spacer()
            if isDirty {
                Button(LocalizedStringKey(LocalizationKey.revert)) { revertChanges() }
                Button(LocalizedStringKey(LocalizationKey.saveChanges)) { save() }
                    .buttonStyle(.borderedProminent)
            } else {
                if isActive {
                    Label(LocalizedStringKey(LocalizationKey.usingCurrent), systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Button(LocalizedStringKey(LocalizationKey.useThisVendor)) {
                        onSwitchVendor(vendor.id)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: isDirty) { _, newValue in isDirtyBinding = newValue }
    }

    // MARK: - Form View

    private var formView: some View {
        Form {
            Section(LocalizedStringKey(LocalizationKey.basicInfo)) {
                TextField(LocalizedStringKey(LocalizationKey.nameLabel), text: $name)
                LabeledContent(LocalizedStringKey(LocalizationKey.baseURLLabel)) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField(LocalizedStringKey(LocalizationKey.baseURLLabel), text: $baseURL)
                            .labelsHidden()
                            .textContentType(.URL)
                        if let error = validationErrors["baseURL"] {
                            Text(LocalizedStringKey(error))
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            Section(LocalizedStringKey(LocalizationKey.authSection)) {
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
                        if showToken {
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(authToken, forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 4)
                        }
                        Button { showToken.toggle() } label: {
                            Image(systemName: showToken ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(LocalizedStringKey(LocalizationKey.authTokenHelper))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(LocalizedStringKey(LocalizationKey.modelsSection)) {
                TextField(LocalizedStringKey(LocalizationKey.defaultModelLabel), text: $defaultModel)
                DisclosureGroup(LocalizedStringKey(LocalizationKey.modelMapping), isExpanded: $showAdvancedModels) {
                    TextField(LocalizedStringKey(LocalizationKey.opusModelLabel), text: $opusModel)
                    TextField(LocalizedStringKey(LocalizationKey.sonnetModelLabel), text: $sonnetModel)
                    TextField(LocalizedStringKey(LocalizationKey.haikuModelLabel), text: $haikuModel)
                    TextField(LocalizedStringKey(LocalizationKey.smallFastModelLabel), text: $smallFastModel)
                }
            }

            Section(LocalizedStringKey(LocalizationKey.connectionSection)) {
                LabeledContent(LocalizedStringKey(LocalizationKey.timeoutLabel)) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField(LocalizedStringKey(LocalizationKey.timeoutLabel), text: $timeout)
                            .labelsHidden()
                        if let error = validationErrors["timeout"] {
                            Text(LocalizedStringKey(error))
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Footer View

    private var footerView: some View {
        HStack {
            Button(action: testConnection) {
                if isTesting {
                    ProgressView().controlSize(.small).padding(.horizontal, 4)
                } else {
                    Label(LocalizedStringKey(LocalizationKey.testConnection), systemImage: "network")
                }
            }
            .disabled(isTesting || baseURL.isEmpty)

            if let result = testResult {
                if result {
                    Label(LocalizedStringKey(LocalizationKey.connectionSuccess), systemImage: "checkmark")
                        .foregroundColor(.green)
                } else {
                    Label(testMessage ?? LocalizationKey.localized(LocalizationKey.connectionFailedSimple),
                          systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Actions

    private func revertChanges() {
        name = originalVendor.name
        let env = originalVendor.env
        baseURL = env["ANTHROPIC_BASE_URL"] ?? ""
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
        if name.isEmpty { errors["name"] = LocalizationKey.validationNameRequired }
        if !baseURL.isEmpty {
            if !baseURL.lowercased().hasPrefix("http://") &&
                !baseURL.lowercased().hasPrefix("https://") {
                errors["baseURL"] = LocalizationKey.validationURLInvalid
            }
        }
        if !timeout.isEmpty {
            if let val = Int(timeout), val >= 1000, val <= 300000 {
                // Valid
            } else {
                errors["timeout"] = LocalizationKey.validationTimeoutRange
            }
        }
        if !quiet { self.validationErrors = errors }
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
                    } else {
                        testResult = false
                        testMessage = String(format: LocalizationKey.localized(LocalizationKey.connectionErrorStatus),
                                         String(httpResponse.statusCode))
                    }
                }
            }
        }.resume()
    }
}
