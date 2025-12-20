#!/bin/bash

# CCSwitch 构建脚本

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/CCSwitch"
BUILD_DIR="$PROJECT_DIR/build"
SCHEME="CCSwitch"

echo "🔨 开始构建 CCSwitch..."

# 清理旧的构建
if [ -d "$BUILD_DIR" ]; then
    echo "🧹 清理旧构建..."
    rm -rf "$BUILD_DIR"
fi

# 创建构建目录
mkdir -p "$BUILD_DIR"

# 构建
echo "📦 编译项目..."
cd "$PROJECT_DIR"
xcodebuild \
    -project CCSwitch.xcodeproj \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    build

# 查找构建的应用
APP_PATH=$(find "$BUILD_DIR" -name "CCSwitch.app" -type d | head -n 1)

if [ -n "$APP_PATH" ]; then
    echo "✅ 构建成功！"
    echo "📁 应用路径: $APP_PATH"

    # 3. 复制到项目根目录
    cp -R "$APP_PATH" "$PROJECT_DIR/"
    echo "📁 应用已同步至: $PROJECT_DIR/CCSwitch.app"

    # 自动运行（仅在非 CI 环境下）
    if [ "$GITHUB_ACTIONS" != "true" ]; then
        open "$PROJECT_DIR/CCSwitch.app"
        echo "✨ 应用已启动！"
    else
        echo "⏭️  CI 环境，跳过自动运行。"
    fi
else
    echo "❌ 构建失败：未找到应用程序"
    exit 1
fi

# 运行测试
if [ "$GITHUB_ACTIONS" != "true" ]; then
    echo ""
    read -p "🧪 是否运行单元测试？ (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔍 运行测试..."
        xcodebuild test \
            -project CCSwitch.xcodeproj \
            -scheme "$SCHEME" \
            -destination 'platform=macOS'
        echo "✅ 测试完成！"
    fi
fi