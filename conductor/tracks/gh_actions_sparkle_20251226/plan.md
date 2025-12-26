# Implementation Plan: GitHub Actions 自动打包 + Sparkle 在线更新

## Phase 1: Sparkle 本地配置与验证
- [x] Task: 检查并配置 `Info.plist`
    - 验证 `SUFeedURL` 是否指向预期的更新源（例如 GitHub Pages 或 Raw GitHub URL）。
    - 验证是否已生成并配置 Sparkle EdDSA 公钥 (`SUPublicEDKey`)。如果没有，需使用 Sparkle 的 `generate_keys` 工具生成。
- [x] Task: 确保 Sparkle 依赖正确集成
    - 验证 Package.swift 或 Xcode Project 中 Sparkle 库的链接状态。

## Phase 2: 密钥准备 (EdDSA)
- [x] Task: 生成并配置 Sparkle EdDSA 密钥
    - 用户已生成公钥并在 Info.plist 中配置。
- [x] Task: 配置 GitHub Secrets
    - 指导用户在仓库 Settings -> Secrets and variables -> Actions 中添加：
        - `SPARKLE_PRIVATE_KEY` (生成密钥时得到的私钥，用于在 CI 中给更新包签名)

## Phase 3: 构建自动化脚本 (Workflow)
- [x] Task: 创建 `.github/workflows/release.yml`
    - [x] Sub-task: 定义触发规则 (`on: push: tags: 'v*'`)。
    - [x] Sub-task: 编写 Checkout 和依赖安装步骤。
    - [x] Sub-task: 编写 Build 步骤 (`xcodebuild build ...`)。
    - [x] Sub-task: 编写打包步骤 (生成 ZIP)。
    - [x] Sub-task: 编写 Sparkle Appcast 生成步骤 (使用私钥给 ZIP 签名并生成 xml)。
    - [x] Sub-task: 编写 Release 发布步骤。

## Phase 4: 测试与验收
- [x] Task: 推送测试 Tag (e.g., `v0.0.1-test`)
    - 观察 Actions 运行日志，修复可能出现的构建或签名错误。
- [x] Task: 验证发布产物
    - 下载 Release 中的 App，验证能否正常打开且无安全警告。
    - 验证 `appcast.xml` 内容是否正确包含新版本的下载链接和签名。
- [x] Task: 模拟更新
    - 在本地运行低版本 App，验证能否检测到刚刚发布的更新。
