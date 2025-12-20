# CCSwitch for macOS

一个用于快速切换 Claude Code 供应商的 macOS 状态栏工具。

## 功能特性

### ✅ 已实现功能

1. **状态栏集成**
   - macOS 状态栏图标显示
   - 当前供应商简称显示（可选）
   - 工具提示显示当前供应商信息

2. **供应商切换**
   - 一键切换 Claude Code 供应商
   - 支持多个供应商配置
   - 当前供应商标记（✓）

3. **配置管理**
   - 自动读取和写入 `~/.claude/settings.json`
   - 集中管理供应商配置（`~/.ccswitch/ccs.json`）
   - 配置自动备份机制

4. **设置界面**
   - General：通用设置、路径显示
   - 供应商管理：增删改查供应商
   - Advanced：备份管理、高级操作

5. **安全特性**
   - 切换前自动备份当前配置
   - 配置文件损坏保护
   - 权限检查和错误处理

6. **用户体验**
   - 切换成功通知
   - 详细的错误提示
   - 日志记录和问题报告

## 安装使用

### 构建要求

- macOS 11.0+
- Xcode 12.0+
- Swift 5.3+

### 构建步骤

1. 克隆项目：
```bash
git clone https://github.com/yourusername/ccswitch-mac.git
cd ccswitch-mac/CCSwitch
```

2. 使用 Xcode 打开项目：
```bash
open CCSwitch.xcodeproj
```

3. 选择目标设备并运行

### 配置供应商

1. 在状态栏点击 CCSwitch 图标
2. 选择"设置..."
3. 在"供应商管理"标签页添加或编辑供应商

### 切换供应商

1. 点击状态栏图标
2. 选择要切换到的供应商
3. 配置将自动更新

## 配置文件格式

### CCSwitch 配置 (~/.ccswitch/ccs.json)

```json
{
  "version": 1,
  "current": "anthropic",
  "vendors": [
    {
      "id": "anthropic",
      "displayName": "Anthropic",
      "claudeSettingsPatch": {
        "provider": "anthropic",
        "model": "claude-3-5-sonnet",
        "apiKeyEnv": "ANTHROPIC_API_KEY"
      }
    },
    {
      "id": "deepseek",
      "displayName": "DeepSeek",
      "claudeSettingsPatch": {
        "provider": "deepseek",
        "model": "deepseek-chat",
        "apiKeyEnv": "DEEPSEEK_API_KEY"
      }
    }
  ]
}
```

### Claude 配置 (~/.claude/settings.json)

应用会自动更新此文件的以下字段：
- provider
- model
- apiKeyEnv
- baseURL（可选）

## 项目结构

```
CCSwitch/
├── CCSwitch.xcodeproj
├── CCSwitch/
│   ├── App/
│   │   ├── CCSwitchApp.swift        # 应用入口
│   │   └── MenuBarController.swift  # 状态栏控制器
│   ├── Models/
│   │   ├── Vendor.swift             # 供应商模型
│   │   ├── CCSConfig.swift          # CCSwitch 配置
│   │   └── ClaudeSettings.swift     # Claude 配置模型
│   ├── Services/
│   │   ├── ConfigManager.swift      # 配置管理服务
│   │   ├── BackupManager.swift      # 备份管理
│   │   ├── Logger.swift            # 日志系统
│   │   └── ErrorHandler.swift      # 错误处理
│   ├── Views/
│   │   ├── SettingsView.swift       # 设置窗口主视图
│   │   ├── GeneralSettingsView.swift
│   │   ├── VendorManagementView.swift
│   │   ├── VendorEditView.swift
│   │   └── AdvancedSettingsView.swift
│   └── Resources/
│       └── Info.plist
└── Tests/
    └── CCSwitchTests/
        ├── ConfigManagerTests.swift
        └── ModelTests.swift
```

## 测试

运行单元测试：

```bash
xcodebuild test -scheme CCSwitch
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 更新日志

### v1.0.0 (2025-12-20)
- 初始版本发布
- 实现所有核心功能
- 支持供应商切换和配置管理