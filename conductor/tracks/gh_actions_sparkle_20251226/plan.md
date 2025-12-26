# Implementation Plan: GitHub Actions 自动打包 + Sparkle 在线更新

## Phase 1: Sparkle 本地配置与验证
- [ ] Task: 检查并配置 `Info.plist`
    - 验证 `SUFeedURL` 是否指向预期的更新源（例如 GitHub Pages 或 Raw GitHub URL）。
    - 验证是否已生成并配置 Sparkle EdDSA 公钥 (`SUPublicEDKey`)。如果没有，需使用 Sparkle 的 `generate_keys` 工具生成。
- [ ] Task: 确保 Sparkle 依赖正确集成
    - 验证 Package.swift 或 Xcode Project 中 Sparkle 库的链接状态。

## Phase 2: 证书与密钥准备 (需用户配合)
- [ ] Task: 导出 macOS 开发者证书
    - 导出 "Developer ID Application" 证书为 `.p12` 文件。
    - 获取证书密码。
- [ ] Task: 获取公证所需的凭证
    - 获取 Apple ID (email)。
    - 生成 App-Specific Password。
    - 获取 Team ID。
- [ ] Task: 配置 GitHub Secrets
    - 指导用户在仓库 Settings -> Secrets and variables -> Actions 中添加：
        - `MACOS_CERTIFICATE` (Base64 encoded .p12)
        - `MACOS_CERTIFICATE_PWD`
        - `MACOS_NOTARIZATION_APPLE_ID`
        - `MACOS_NOTARIZATION_APP_SPECIFIC_PWD`
        - `MACOS_NOTARIZATION_TEAM_ID`

## Phase 3: 构建自动化脚本 (Workflow)
- [ ] Task: 创建 `.github/workflows/release.yml`
    - [ ] Sub-task: 定义触发规则 (`on: push: tags: 'v*'`)。
    - [ ] Sub-task: 编写 Checkout 和依赖安装步骤。
    - [ ] Sub-task: 编写 Build 步骤 (`xcodebuild archive ...`)。
    - [ ] Sub-task: 编写 Code Signing 步骤 (解码证书 -> 导入 Keychain -> 签名)。
    - [ ] Sub-task: 编写打包步骤 (生成 ZIP/DMG)。
    - [ ] Sub-task: 编写 Notarization 步骤 (`xcrun notarytool ...` & `xcrun stapler ...`)。
    - [ ] Sub-task: 编写 Sparkle Appcast 生成步骤 (使用 Sparkle 的 `generate_appcast` 工具或脚本生成)。
    - [ ] Sub-task: 编写 Release 发布步骤 (使用 `softprops/action-gh-release` 等 Action 上传产物)。

## Phase 4: 测试与验收
- [ ] Task: 推送测试 Tag (e.g., `v0.0.1-test`)
    - 观察 Actions 运行日志，修复可能出现的构建或签名错误。
- [ ] Task: 验证发布产物
    - 下载 Release 中的 App，验证能否正常打开且无安全警告。
    - 验证 `appcast.xml` 内容是否正确包含新版本的下载链接和签名。
- [ ] Task: 模拟更新
    - 在本地运行低版本 App，验证能否检测到刚刚发布的更新。
