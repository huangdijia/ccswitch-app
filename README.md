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
   - 集中管理供应商配置（`~/.ccswitch/vendors.json`）
   - 配置自动备份机制

4. **设置界面**
   - General：通用设置、路径显示、通知权限管理
   - 供应商管理：增删改查供应商，支持从旧配置导入
   - Advanced：备份管理、高级操作

5. **安全特性**
   - 切换前自动备份当前配置
   - 配置文件损坏保护
   - 权限检查和错误处理

6. **用户体验**
   - 状态栏联动切换
   - 切换成功通知（需授予通知权限）
   - 通知权限检测和引导
   - 详细的错误提示
   - 日志记录和问题报告
   - 多语言支持（简体中文、繁体中文、英文）

## 安装使用

### 下载安装

1. 从 GitHub Releases 下载最新的 `CCSwitch.dmg`。
2. 将 `CCSwitch.app` 拖入 `Applications` 文件夹。
3. **重要提示**：由于应用未进行 Apple 开发者签名，首次安装后需在终端执行以下命令以解决“应用已损坏”或“无法验证开发者”的问题：

   ```bash
   xattr -rd com.apple.quarantine /Applications/CCSwitch.app/
   ```

### 源码构建 (开发用)

#### 构建要求

- macOS 14.6+
- Xcode 15.0+
- Swift 5.9+

### 构建步骤

1. 克隆项目：

```bash
git clone https://github.com/huangdijia/ccswitch-app.git
cd ccswitch-app
```

2. 运行构建脚本：

```bash
./build.sh
```

#### 开发构建和调试

项目提供了多个辅助脚本用于开发：

- **compile_swift.sh** - 使用 Swift 编译器直接编译（无需 Xcode）
- **run_dev.sh** - 开发模式运行（自动解除安全限制）
- **test_app.sh** - 测试应用基本功能
- **fix_and_run.sh** - 修复并运行应用（适用于首次运行）

快速开发运行：

```bash
./run_dev.sh
```

### 配置供应商

1. 在状态栏点击 CCSwitch 图标
2. 选择"设置..."
3. 在"供应商管理"标签页添加、编辑或导入供应商

### 切换供应商

1. 点击状态栏图标
2. 选择要切换到的供应商，或者在设置界面的供应商列表中切换开关
3. 配置将自动更新

## 配置文件格式

### CCSwitch 配置 (~/.ccswitch/vendors.json)

```json
{
  "version": 1,
  "current": "anthropic",
  "vendors": [
    {
      "id": "default",
      "displayName": "Default",
      "claudeSettingsPatch": {}
    },
    {
      "id": "deepseek",
      "displayName": "DeepSeek",
      "claudeSettingsPatch": {
        "ANTHROPIC_AUTH_TOKEN": "sk-xxxxxx",
        "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
        "ANTHROPIC_MODEL": "deepseek-chat",
        "ANTHROPIC_SMALL_FAST_MODEL": "deepseek-chat"
      }
    }
  ]
}
```

> **注意**：配置文件路径为 `~/.ccswitch/vendors.json`，参考示例文件 `CCSwitch/vendors.json.example`

### Claude 配置 (~/.claude/settings.json)

应用会自动更新此文件的 `env` 字段，保留其他现有字段。

## 项目结构

```
ccswitch-app/
├── build.sh                          # 主构建脚本
├── compile_swift.sh                  # Swift 编译脚本
├── run_dev.sh                        # 开发运行脚本
├── test_app.sh                       # 应用测试脚本
├── fix_and_run.sh                    # 修复并运行脚本
├── README.md                         # 项目说明
├── README_XCODE.md                   # Xcode 使用指南
└── CCSwitch/
    ├── CCSwitch.xcodeproj            # Xcode 项目文件
    ├── CCSwitch.xcworkspace          # Xcode 工作空间
    ├── vendors.json.example         # 配置文件示例
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
    │   │   ├── GeneralSettingsView.swift    # 通用设置（含通知权限）
    │   │   ├── VendorManagementView.swift   # 供应商管理
    │   │   ├── VendorEditView.swift         # 供应商编辑
    │   │   └── AdvancedSettingsView.swift   # 高级设置
    │   └── Resources/
    │       ├── Info.plist
    │       ├── AppIcon.icns
    │       ├── en.lproj/                # 英文本地化
    │       ├── zh-Hans.lproj/           # 简体中文本地化
    │       └── zh-Hant.lproj/           # 繁体中文本地化
    └── CCSwitchTests/
        ├── ConfigManagerTests.swift
        └── ModelTests.swift
```

## 测试

运行单元测试：

```bash
cd CCSwitch
xcodebuild test -project CCSwitch.xcodeproj -scheme CCSwitch -destination 'platform=macOS'
```

或使用测试脚本：

```bash
./test_app.sh
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 更新日志

### v1.0.0 (2025-12-21)

- 初始版本发布
- 实现所有核心功能
- 支持供应商切换和配置管理
- 支持通知权限检测和引导
- 多语言支持（简体中文、繁体中文、英文）
- 提供多个开发辅助脚本
