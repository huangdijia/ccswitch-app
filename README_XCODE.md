# 在 Xcode 中打开 CCSwitch 项目

## 方法 1：安装 Xcode（推荐）

如果尚未安装完整的 Xcode IDE：

1. 从 App Store 安装 Xcode：
   - 打开 App Store
   - 搜索 "Xcode"
   - 点击 "获取" 或 "安装"

2. 或者从 Apple 开发者网站下载：
   - 访问 https://developer.apple.com/xcode/
   - 下载最新版本的 Xcode

3. 安装完成后，运行以下命令打开项目：
```bash
open CCSwitch.xcodeproj
```

## 方法 2：使用命令行编译

如果只想使用命令行工具编译项目：

```bash
# 进入项目目录
cd /Users/hdj/github/huangdijia/ccswitch-app/CCSwitch

# 编译项目
xcodebuild -project CCSwitch.xcodeproj -scheme CCSwitch -configuration Debug build

# 运行测试
xcodebuild test -project CCSwitch.xcodeproj -scheme CCSwitch -destination 'platform=macOS'
```

## 项目结构概览

```
CCSwitch/
├── CCSwitch.xcodeproj     # Xcode 项目文件
├── CCSwitch/              # 主要源代码
│   ├── App/              # 应用入口和状态栏控制
│   ├── Models/           # 数据模型
│   ├── Services/         # 业务逻辑服务
│   ├── Views/            # SwiftUI 界面
│   └── Resources/        # 资源文件
└── CCSwitchTests/        # 单元测试
```

## 配置说明

- **最低系统要求**: macOS 11.0+
- **开发语言**: Swift 5.0+
- **UI 框架**: AppKit + SwiftUI
- **测试框架**: XCTest

## 编译步骤

1. 打开终端，进入项目目录
2. 如果使用 Xcode IDE，直接双击 `CCSwitch.xcodeproj` 文件
3. 如果使用命令行：
   ```bash
   xcodebuild -project CCSwitch.xcodeproj -scheme CCSwitch build
   ```
4. 编译成功后，应用将在 `build/Debug/CCSwitch.app` 生成

## 运行应用

编译成功后，可以直接运行：
```bash
open build/Debug/CCSwitch.app
```

应用将出现在 macOS 状态栏中，显示为 "CC" 图标。