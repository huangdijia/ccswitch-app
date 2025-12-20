import SwiftUI

struct VendorEditView: View {
    let vendor: Vendor?
    let onSave: (Vendor) -> Void
    let onCancel: () -> Void

    @State private var id: String = ""
    @State private var displayName: String = ""
    @State private var provider: String = "anthropic"
    @State private var notes: String = ""
    @State private var env: [String: String] = [:]

    // Constants
    private let commonProviders = ["anthropic", "deepseek", "openai"]
    
    // Explicitly requested keys to show in UI
    private let envKeys = [
        "ANTHROPIC_AUTH_TOKEN",
        "ANTHROPIC_BASE_URL",
        "ANTHROPIC_MODEL",
        "ANTHROPIC_SMALL_FAST_MODEL",
        "ANTHROPIC_DEFAULT_OPUS_MODEL",
        "ANTHROPIC_DEFAULT_SONNET_MODEL",
        "ANTHROPIC_DEFAULT_HAIKU_MODEL",
        "API_TIMEOUT_MS"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(vendor == nil ? "add_vendor" : "edit_vendor")
                .font(.headline)

            Form {
                Section(header: Text("Basic Info")) {
                    HStack {
                        Text("ID:")
                            .frame(width: 80, alignment: .leading)
                        TextField("Unique ID", text: $id)
                            .disabled(vendor != nil)
                    }

                    HStack {
                        Text("Name:")
                            .frame(width: 80, alignment: .leading)
                        TextField("Display Name", text: $displayName)
                    }
                    
                    HStack {
                        Text("Provider:")
                            .frame(width: 80, alignment: .leading)
                        Picker("", selection: $provider) {
                            ForEach(commonProviders, id: \.self) { p in
                                Text(p).tag(p)
                            }
                            Text("Custom").tag("")
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 120)
                        
                        if !commonProviders.contains(provider) {
                            TextField("Custom Provider", text: $provider)
                        }
                    }
                }

                Section(header: Text("Environment Variables")) {
                    ForEach(envKeys, id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 220, alignment: .leading)
                                .help(key)
                            TextField("Value", text: Binding(
                                get: { env[key] ?? "" },
                                set: { env[key] = $0.isEmpty ? nil : $0 }
                            ))
                        }
                    }
                    
                    // Button to add other keys? For now, just the requested ones + what was already there.
                    // If there are keys in `env` that are NOT in `envKeys`, show them too?
                    ForEach(env.keys.sorted().filter { !envKeys.contains($0) && $0 != "provider" }, id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 220, alignment: .leading)
                            TextField("Value", text: Binding(
                                get: { env[key] ?? "" },
                                set: { env[key] = $0.isEmpty ? nil : $0 }
                            ))
                        }
                    }
                }

                Section(header: Text("Notes")) {
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
                .disabled(id.isEmpty || displayName.isEmpty || provider.isEmpty)
            }
        }
        .padding()
        .frame(width: 600, height: 700)
        .onAppear {
            loadVendorData()
        }
    }

    private func loadVendorData() {
        if let vendor = vendor {
            id = vendor.id
            displayName = vendor.name
            env = vendor.env
            provider = env["provider"] ?? "anthropic"
            notes = vendor.notes ?? ""
        } else {
            // Defaults for new vendor
            provider = "anthropic"
            env["ANTHROPIC_MODEL"] = "claude-3-5-sonnet"
        }
    }

    private func save() {
        var finalEnv = env
        finalEnv["provider"] = provider
        
        // Clean up empty values
        for (key, value) in finalEnv {
            if value.isEmpty {
                finalEnv.removeValue(forKey: key)
            }
        }

        let newVendor = Vendor(
            id: id,
            name: displayName,
            env: finalEnv,
            notes: notes.isEmpty ? nil : notes
        )

        onSave(newVendor)
    }
}