# Specification: GitHub Actions 自动打包 + Sparkle 在线更新

## 1. Overview
本 Track 旨在为 CCSwitch 建立一套完整的自动化发布流程（CI/CD）并启用 Sparkle 在线更新功能。通过 GitHub Actions，当仓库推送新的 Tag 时，自动触发构建、测试、代码签名、公证（Notarization）、打包（DMG/ZIP）以及生成 Sparkle 所需的 `appcast.xml`。这将极大地简化发布流程，并确保用户能及时获取最新版本。

## 2. Functional Requirements

### 2.1 GitHub Actions Workflow
- **触发机制**：仅在推送以 `v` 开头的 Tag（如 `v1.0.0`）时触发。
- **构建环境**：使用 `macos-latest`。
- **构建步骤**：
    - 拉取代码。
    - 安装依赖（通过 SPM）。
    - 运行单元测试。
    - 使用 `xcodebuild` 编译 Release 版本。
- **打包**：
    - 将 `.app` 直接打包为 ZIP。
- **发布产物**：
    - 创建 GitHub Release。
    - 上传打包好的文件（.zip/.dmg）到 Release Assets。
    - 自动生成并上传/更新 `appcast.xml` 到指定位置（如 GitHub Pages 或 Release Assets）。

### 2.2 Sparkle Integration
- **客户端配置**：
    - 确保 `Info.plist` 中包含正确的 `SUFeedURL`。
    - 确保 `Info.plist` 中包含 Sparkle 的公钥（`SUPublicEDKey`）。
- **更新检查**：App 启动或用户手动点击“检查更新”时，能正确读取远程 xml 并提示更新。

## 3. Non-Functional Requirements
- **安全性**：所有的证书密码、API Key 等敏感信息必须存储在 GitHub Secrets 中，严禁硬编码。
- **稳定性**：构建脚本应具备错误处理能力，任何步骤失败都应导致 Workflow 失败并通知。

## 4. Acceptance Criteria
- [ ] 推送 `vX.Y.Z` Tag 后，GitHub Actions 能成功运行完毕（绿色）。
- [ ] GitHub Releases 页面出现对应的 Release 草稿或正式版，且包含已签名的 `.zip` 或 `.dmg` 文件。
- [ ] 下载产物后，在 macOS 上运行不会提示“无法打开”或“恶意软件”警告（证明公证成功）。
- [ ] 运行旧版本的 App，点击“检查更新”能检测到新发布的版本。
