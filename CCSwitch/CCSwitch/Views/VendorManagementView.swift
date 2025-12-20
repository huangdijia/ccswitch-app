import SwiftUI

struct VendorManagementView: View {
    @State private var vendors: [Vendor] = []
    @State private var selectedVendor: Vendor?
    private let currentVendorId = ConfigManager.shared.currentVendor?.id ?? ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题和说明
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "server.rack")
                        .foregroundColor(.blue)
                        .font(.system(size: 18, weight: .semibold))

                    Text("供应商管理")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()
                }

                Text("显示所有可用的 Claude Code 供应商。点击可查看详情或切换供应商。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // 配置文件位置
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Text("配置文件: ~/.ccswitch/ccs.json")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)

            // 供应商列表
            if vendors.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 64, height: 64)

                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.orange)
                    }

                    Text("未找到供应商配置")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("请检查 ~/.ccswitch/ccs.json 文件是否存在且格式正确")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(vendors) { vendor in
                            VendorCard(
                                vendor: vendor,
                                isCurrent: vendor.id == currentVendorId,
                                onSwitch: {
                                    try? ConfigManager.shared.switchToVendor(with: vendor.id)
                                    loadVendors()
                                },
                                onDetail: {
                                    selectedVendor = vendor
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .onAppear {
            loadVendors()
        }
        .sheet(item: $selectedVendor) { vendor in
            VendorDetailView(vendor: vendor, isCurrent: vendor.id == currentVendorId)
        }
    }

    private func loadVendors() {
        vendors = ConfigManager.shared.allVendors
    }
}

// MARK: - Vendor Card
struct VendorCard: View {
    let vendor: Vendor
    let isCurrent: Bool
    let onSwitch: () -> Void
    let onDetail: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // 供应商图标
            ZStack {
                Circle()
                    .fill(
                        isCurrent
                            ? Color.green.opacity(0.15)
                            : Color.gray.opacity(0.1)
                    )
                    .frame(width: 48, height: 48)

                Circle()
                    .stroke(
                        isCurrent ? Color.green : Color.gray.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 48, height: 48)

                if isCurrent {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .font(.system(size: 16, weight: .bold))
                } else {
                    Image(systemName: "server.rack")
                        .foregroundColor(.gray)
                        .font(.system(size: 16, weight: .medium))
                }
            }

            // 供应商信息
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(vendor.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    if isCurrent {
                        Text("当前使用")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(vendor.claudeSettingsPatch.model)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let baseURL = vendor.claudeSettingsPatch.baseURL {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(baseURL)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }

            Spacer()

            // 操作按钮组
            HStack(spacing: 8) {
                // 详情按钮
                Button(action: onDetail) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                // 切换按钮
                if !isCurrent {
                    Button(action: onSwitch) {
                        Text("切换")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isCurrent ? Color.green.opacity(0.5) : Color.gray.opacity(0.1),
                    lineWidth: isCurrent ? 2 : 1
                )
        )
        .scaleEffect(isCurrent ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isCurrent)
    }
}

// MARK: - Vendor Detail View
struct VendorDetailView: View {
    let vendor: Vendor
    let isCurrent: Bool
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            // 标题区域
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 64, height: 64)

                    Image(systemName: "server.rack")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.blue)
                }

                HStack(spacing: 10) {
                    Text(vendor.displayName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    if isCurrent {
                        Text("当前使用")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green)
                            .cornerRadius(5)
                    }
                }
            }
            .padding(.top, 8)

            // 配置详情卡片
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.purple)
                        .font(.system(size: 16, weight: .semibold))

                    Text("配置详情")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(.bottom, 4)

                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Provider", value: vendor.claudeSettingsPatch.provider)
                    DetailRow(label: "Model", value: vendor.claudeSettingsPatch.model)
                    DetailRow(label: "API Key Env", value: vendor.claudeSettingsPatch.apiKeyEnv)
                    if let baseURL = vendor.claudeSettingsPatch.baseURL {
                        DetailRow(label: "Base URL", value: baseURL)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )

            Spacer()

            // 操作按钮
            HStack(spacing: 12) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("关闭")
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())

                if !isCurrent {
                    Button(action: {
                        try? ConfigManager.shared.switchToVendor(with: vendor.id)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("切换到此供应商")
                            .font(.body)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .frame(width: 520, height: 420)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(16)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}