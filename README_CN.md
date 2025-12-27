# CCSwitch for macOS

[![GitHub Release](https://img.shields.io/github/v/release/huangdijia/ccswitch-app)](https://github.com/huangdijia/ccswitch-app/releases)
[![GitHub Downloads](https://img.shields.io/github/downloads/huangdijia/ccswitch-app/total)](https://github.com/huangdijia/ccswitch-app/releases)
[![GitHub License](https://img.shields.io/github/license/huangdijia/ccswitch-app)](LICENSE)

一个用于快速切换 Claude Code 供应商的 macOS 状态栏工具。

[English](README.md)

![CCSwitch Screenshot](Screenshots/02.png)

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
   - 预置供应商模板（Anthropic、DeepSeek、OpenAI等）
   - 收藏功能，快速访问常用供应商

3. **配置管理**
   - 自动读取和写入 `~/.claude/settings.json`
   - 集中管理供应商配置（`~/.ccswitch/vendors.json`）
   - 配置自动备份机制
   - 支持配置模板复用
   - 自动从旧版配置格式迁移

4. **设置界面**
   - 通用：通用设置、路径显示、通知权限管理、软件更新
   - 供应商管理：增删改查供应商，支持从旧配置导入
   - 高级：备份管理、高级操作、iCloud 同步设置

5. **iCloud 同步** 🆕
   - 跨多台 Mac 双向同步
   - 自动冲突检测和解决界面
   - 网络监控，支持离线/在线状态跟踪
   - 自动重试，支持指数退避
   - 实时同步状态显示

6. **Toast 通知** 🆕
   - 成功、信息和错误提示类型
   - 基于 SwiftUI 的平滑动画覆盖层
   - 2 秒后自动消失
   - 支持多个通知排队

7. **安全特性**
   - 切换前自动备份当前配置
   - 配置文件损坏保护
   - 权限检查和错误处理
   - Ed25519 签名验证软件更新

8. **用户体验**
   - 状态栏联动切换
   - 切换成功通知（需授予通知权限）
   - 通知权限检测和引导
   - 详细的错误提示
   - 日志记录和问题报告
   - 多语言支持（简体中文、繁体中文、英文）
   - 未保存更改检测和确认提示

9. **架构优化**
   - 协议导向架构（Protocol-Oriented Architecture）
   - 依赖注入模式提升可测试性
   - 清晰的关注点分离
   - 易于扩展的模块化设计

10. **自动更新**
    - 基于 GitHub Releases 的自动更新检查
    - 自动下载和安装更新选项
    - 手动检查更新功能
    - 更新进度显示
    - Sparkle 集成，支持 Ed25519 签名验证

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

2. 运行构建脚本（多种方式）：

使用 Makefile（推荐）：

```bash
make build      # 完整构建（需要 Xcode）
make fast-build # 快速构建（仅需 Swift 命令行工具）
make run        # 构建并运行
make test       # 运行单元测试（需要 Xcode）
```

或使用 shell 脚本：

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

## iCloud 同步

CCSwitch 支持 **iCloud 同步**功能，让您的供应商配置在多台 Mac 间保持同步。

### 功能特性

- **双向同步**：在任何 Mac 上进行的更改会自动同步到您的所有其他设备
- **冲突解决**：当检测到冲突时，您可以选择保留哪个版本（本地或远程）
- **网络感知**：自动检测离线/在线状态，连接恢复后自动同步
- **自动重试**：使用指数退避策略重试失败的同步操作（最多 3 次）
- **实时状态**：直接在高级设置中查看同步状态

### 工作原理

1. **启用同步**：前往 设置 → 高级 → 启用 "iCloud 同步"
2. **自动上传**：对供应商的更改会自动上传到 iCloud（2 秒防抖）
3. **自动下载**：来自其他设备的更改会被自动检测并下载
4. **冲突处理**：如果本地和远程版本同时更改，您会看到冲突解决对话框

### 同步状态

| 状态 | 描述 |
|------|------|
| 🟤 空闲 | 已启用同步，无待处理的更改 |
| 🔵 同步中 | 正在上传/下载更改 |
| 🟢 已同步 | 更改成功同步 |
| 🟠 离线 | 无网络连接，同步暂停 |
| 🔴 错误 | 同步失败（查看日志了解详情） |

### 要求

- **iCloud 账户**：必须在 Mac 上登录 iCloud
- **iCloud 键值存储**：必须在 系统设置 → Apple ID → iCloud 中启用
- **网络连接**：需要有效的互联网连接才能同步

### 技术详情

- **存储**：使用 `NSUbiquitousKeyValueStore` 进行 iCloud 键值存储
- **数据大小**：每个供应商配置以 JSON 编码数据存储
- **冲突检测**：比较本地和远程供应商版本
- **隐私**：所有数据由 Apple 的 iCloud 基础设施加密

## 项目结构

```
ccswitch-app/
├── build.sh                          # 主构建脚本
├── compile_swift.sh                  # Swift 编译脚本
├── run_dev.sh                        # 开发运行脚本
├── test_app.sh                       # 应用测试脚本
├── fix_and_run.sh                    # 修复并运行脚本
├── Makefile                          # Make 构建系统
├── appcast.xml                       # Sparkle 更新源
├── README.md                         # 项目说明
├── README_CN.md                      # 中文文档
├── README_XCODE.md                   # Xcode 使用指南
├── ARCHITECTURE.md                   # 架构文档
├── EXTENSION_GUIDE.md                # 扩展指南
├── CONTRIBUTING.md                   # 贡献指南
├── BUILD_REQUIREMENTS.md             # 构建要求说明
└── CCSwitch/
    ├── CCSwitch.xcodeproj            # Xcode 项目文件
    ├── CCSwitch.xcworkspace          # Xcode 工作空间
    ├── vendors.json.example         # 配置文件示例
    ├── CCSwitch/
    │   ├── App/
    │   │   ├── CCSwitchApp.swift        # 应用入口
    │   │   ├── MenuBarController.swift  # 状态栏控制器
    │   │   └── AppInfo.swift            # 应用版本信息
    │   ├── Models/
    │   │   ├── Vendor.swift             # 供应商模型
    │   │   ├── VendorTemplate.swift     # 供应商模板
    │   │   ├── CCSConfig.swift          # CCSwitch 配置
    │   │   └── ClaudeSettings.swift     # Claude 配置模型
    │   ├── Protocols/                   # 协议定义
    │   │   ├── VendorSwitcher.swift        # 供应商切换协议
    │   │   ├── ConfigurationRepository.swift # 配置仓库协议
    │   │   ├── SettingsWriter.swift        # 设置写入协议
    │   │   ├── BackupService.swift         # 备份服务协议
    │   │   ├── NotificationService.swift   # 通知服务协议
    │   │   ├── SettingsRepository.swift    # 设置仓库协议
    │   │   └── CloudStorageService.swift   # iCloud 存储协议 🆕
    │   ├── Services/
    │   │   ├── ConfigManager.swift      # 配置管理服务
    │   │   ├── ServiceContainer.swift   # 依赖注入容器
    │   │   ├── UpdateManager.swift      # 自动更新管理器
    │   │   ├── SyncManager.swift        # iCloud 同步管理器 🆕
    │   │   ├── ICloudStorageService.swift # iCloud 存储实现 🆕
    │   │   ├── ToastManager.swift      # Toast 通知管理器 🆕
    │   │   ├── BackupManager.swift      # 备份管理
    │   │   ├── Logger.swift            # 日志系统
    │   │   └── ErrorHandler.swift      # 错误处理
    │   ├── Views/
    │   │   ├── SettingsView.swift       # 设置窗口主视图
    │   │   ├── GeneralSettingsView.swift    # 通用设置
    │   │   ├── VendorManagementView.swift   # 供应商管理
    │   │   ├── VendorEditView.swift         # 供应商编辑
    │   │   ├── AdvancedSettingsView.swift   # 高级设置
    │   │   ├── SyncStatusView.swift         # 同步状态指示器 🆕
    │   │   ├── SyncConflictResolverView.swift # 冲突解决界面 🆕
    │   │   └── ToastView.swift              # Toast 组件 🆕
    │   └── Resources/
    │       ├── Info.plist
    │       ├── AppIcon.icns
    │       ├── en.lproj/                # 英文本地化
    │       ├── zh-Hans.lproj/           # 简体中文本地化
    │       └── zh-Hant.lproj/           # 繁体中文本地化
    └── CCSwitchTests/
        ├── ConfigManagerTests.swift     # 配置管理测试
        ├── ModelTests.swift             # 模型测试
        ├── CloudStorageServiceTests.swift  # 云存储测试 🆕
        ├── SyncManagerTests.swift      # 同步管理器测试 🆕
        └── Mocks/                       # Mock对象
            ├── MockConfigurationRepository.swift
            ├── MockServices.swift
            └── MockCloudStorageService.swift 🆕
```

## 测试

运行单元测试：

使用 Makefile：

```bash
make test       # 运行单元测试（需要 Xcode）
make test-app   # 运行手动测试脚本
```

或使用命令行：

```bash
cd CCSwitch
xcodebuild test -project CCSwitch.xcodeproj -scheme CCSwitch -destination 'platform=macOS'
```

或使用测试脚本：

```bash
./test_app.sh
```

## 架构

CCSwitch 采用**协议导向架构**（Protocol-Oriented Architecture）配合**依赖注入**模式：

- ✅ **高可测试性**：所有核心组件都有协议定义和 Mock 实现
- ✅ **高复用性**：通过协议抽象和依赖注入实现组件复用
- ✅ **低耦合**：清晰的关注点分离，各层职责明确
- ✅ **易扩展**：新增供应商、存储后端、通知渠道等无需修改核心代码

详细架构文档请参考：

- [ARCHITECTURE.md](ARCHITECTURE.md) - 架构设计详解
- [EXTENSION_GUIDE.md](EXTENSION_GUIDE.md) - 扩展开发指南
- [CONTRIBUTING.md](CONTRIBUTING.md) - 贡献指南

## 贡献

欢迎提交 Issue 和 Pull Request！

在贡献之前，请阅读：

- [CONTRIBUTING.md](CONTRIBUTING.md) - 贡献指南
- [ARCHITECTURE.md](ARCHITECTURE.md) - 了解项目架构
- [EXTENSION_GUIDE.md](EXTENSION_GUIDE.md) - 学习如何扩展功能

## 许可证

MIT License

## 更新日志

### v0.2.3 (2025-12-27)

- 🔧 简化自动更新检查启动逻辑，移除异步任务包装
- 🐛 修复更新检查时序，提高可靠性

### v0.2.2 (2025-12-26)

- ✨ 简化同步逻辑 - 现在自动同步所有供应商（移除选择性同步）
- 🔧 改进同步状态处理 - 云存储写入后始终设置为成功
- 📝 改进磁盘同步失败的日志记录

### v0.2.1 (2025-12-25)

- ✨ **iCloud 同步** - 支持跨多台 Mac 的全双向同步
  - 自动冲突检测和解决界面
  - 网络监控，支持离线/在线状态跟踪
  - 自动重试，支持指数退避
  - 实时同步状态显示
- 🎨 添加 SyncStatusView 实时同步状态
- 🎨 添加 SyncConflictResolverView 冲突解决界面

### v0.2.0 (2025-12-24)

- ✨ **自动化发布工作流** - GitHub Actions 自动构建和发布
- ✨ **Sparkle 集成** - 支持自动更新的 Ed25519 签名验证
- ✨ **DMG 创建** - 自动化 DMG 创建用于分发
- 🎨 改进供应商和设置视图的 UI 对齐
- 🔧 添加本地化包配置
- 🔧 修复 CI 中的 AppIcon 打包

### v0.1.10 (2025-12-23)

- 📝 更新 GitHub 仓库链接为 ccswitch-app
- 🔧 修复 UpdateManager 中的错误处理逻辑
- 📝 添加双语文档（中文和英文 README）

### v0.1.9 (2025-12-22)

- ✨ **预设供应商** - 添加推荐供应商模板
- ✨ 使用预设配置自动初始化
- 🎨 改进供应商管理 UI

### v0.1.8 (2025-12-21)

- ✨ **配置迁移** - 支持从旧版配置格式自动迁移
- 🎨 添加 MigrationAlertView 实现无缝升级
- 🔧 将迁移管理器重构到 ConfigManager 中
- 🔧 改进迁移错误处理
- 📝 添加 GitHub 徽章（版本、下载量、许可证）

### v0.1.7 (2025-12-21)

- ✨ 新增自动更新功能（基于 GitHub Releases）
- ✨ 新增软件更新设置界面
- ✨ 新增 AppInfo 工具类用于获取版本信息
- 🔧 添加 Makefile 支持多种构建方式
- 🔧 完善本地化字符串
- 📝 更新文档和架构说明
- 🎉 初始版本发布
- 🎯 实现所有核心功能
- ✅ 支持供应商切换和配置管理
- ✅ 支持通知权限检测和引导
- ✅ 多语言支持（简体中文、繁体中文、英文）
- 🛠️ 提供多个开发辅助脚本
