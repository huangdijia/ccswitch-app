import SwiftUI

struct VendorEditView: View {
    let vendor: Vendor?
    let onSave: (Vendor) -> Void
    let onCancel: () -> Void

    @State private var id: String = ""
    @State private var displayName: String = ""
    @State private var provider: String = ""
    @State private var model: String = ""
    @State private var apiKeyEnv: String = ""
    @State private var baseURL: String = ""
    @State private var notes: String = ""
    @State private var useCustomBaseURL: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(vendor == nil ? "添加供应商" : "编辑供应商")
                .font(.headline)

            Form {
                Section(header: Text("基本信息")) {
                    HStack {
                        Text("ID：")
                        TextField("唯一标识", text: $id)
                            .disabled(vendor != nil) // 编辑时禁用 ID 修改
                    }

                    HStack {
                        Text("显示名称：")
                        TextField("供应商名称", text: $displayName)
                    }
                }

                Section(header: Text("Claude 配置")) {
                    HStack {
                        Text("Provider：")
                        TextField("供应商类型", text: $provider)
                    }

                    HStack {
                        Text("Model：")
                        TextField("模型名称", text: $model)
                    }

                    HStack {
                        Text("API Key Env：")
                        TextField("环境变量名", text: $apiKeyEnv)
                    }

                    Toggle("自定义 Base URL", isOn: $useCustomBaseURL)

                    if useCustomBaseURL {
                        HStack {
                            Text("Base URL：")
                            TextField("API 地址", text: $baseURL)
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

                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.escape)

                Button("保存") {
                    save()
                }
                .keyboardShortcut(.return)
                .disabled(id.isEmpty || displayName.isEmpty || provider.isEmpty || model.isEmpty || apiKeyEnv.isEmpty)
            }
        }
        .padding()
        .onAppear {
            loadVendorData()
        }
    }

    private func loadVendorData() {
        if let vendor = vendor {
            id = vendor.id
            displayName = vendor.displayName
            provider = vendor.claudeSettingsPatch.provider
            model = vendor.claudeSettingsPatch.model
            apiKeyEnv = vendor.claudeSettingsPatch.apiKeyEnv
            baseURL = vendor.claudeSettingsPatch.baseURL ?? ""
            notes = vendor.notes ?? ""
            useCustomBaseURL = vendor.claudeSettingsPatch.baseURL != nil
        }
    }

    private func save() {
        let patch = ClaudeSettingsPatch(
            provider: provider,
            model: model,
            apiKeyEnv: apiKeyEnv,
            baseURL: useCustomBaseURL ? baseURL : nil
        )

        let newVendor = Vendor(
            id: id,
            displayName: displayName,
            claudeSettingsPatch: patch,
            notes: notes.isEmpty ? nil : notes
        )

        onSave(newVendor)
    }
}