#!/bin/bash

# 使用 Swift 编译器直接构建 CCSwitch

set -e

PROJECT_DIR="/Users/hdj/github/huangdijia/ccswitch-mac/CCSwitch"
OUTPUT_DIR="$PROJECT_DIR/DerivedData"
APP_NAME="CCSwitch"

echo "🔨 使用 Swift 编译器构建 CCSwitch..."

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 编译参数
SWIFT_FLAGS="-O -target x86_64-apple-macos13.0 -I /usr/lib/swift"
LINK_FLAGS="-framework Cocoa -framework SwiftUI -framework Foundation"

# 查找所有 Swift 源文件（排除测试文件）
echo "📝 查找源文件..."
SWIFT_FILES=$(find "$PROJECT_DIR/CCSwitch" -name "*.swift" -type f | tr '\n' ' ')

if [ -z "$SWIFT_FILES" ]; then
    echo "❌ 未找到 Swift 源文件"
    exit 1
fi

echo "📦 找到以下源文件："
echo "$SWIFT_FILES"
echo ""

# 编译
echo "⚙️  编译中..."
cd "$PROJECT_DIR"

# 创建应用程序包结构
APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 复制 Info.plist
if [ -f "$PROJECT_DIR/CCSwitch/Resources/Info.plist" ]; then
    cp "$PROJECT_DIR/CCSwitch/Resources/Info.plist" "$APP_BUNDLE/Contents/"
    # 替换 Info.plist 中的变量
    sed -i '' 's/\$(EXECUTABLE_NAME)/CCSwitch/g' "$APP_BUNDLE/Contents/Info.plist"
    sed -i '' 's/\$(PRODUCT_BUNDLE_IDENTIFIER)/com.cccode.switch/g' "$APP_BUNDLE/Contents/Info.plist"
    sed -i '' 's/\$(PRODUCT_NAME)/CCSwitch/g' "$APP_BUNDLE/Contents/Info.plist"
    sed -i '' 's/\$(DEVELOPMENT_LANGUAGE)/en/g' "$APP_BUNDLE/Contents/Info.plist"
else
    echo "⚠️  Info.plist not found, creating basic one..."
    # ... (existing fallback code)
fi

# 复制图标
if [ -f "$PROJECT_DIR/CCSwitch/Resources/AppIcon.icns" ]; then
    echo "🖼️  复制应用图标..."
    cp "$PROJECT_DIR/CCSwitch/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

# 复制本地化资源
echo "🌍 复制本地化文件..."
for lproj in "$PROJECT_DIR/CCSwitch/Resources"/*.lproj; do
    if [ -d "$lproj" ]; then
        cp -R "$lproj" "$APP_BUNDLE/Contents/Resources/"
    fi
done

# 编译主程序
swiftc $SWIFT_FLAGS $LINK_FLAGS -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" $SWIFT_FILES

if [ $? -eq 0 ]; then
    echo "✅ 编译成功！"
    echo "📁 应用位置: $APP_BUNDLE"

    # 复制到项目根目录
    cp -R "$APP_BUNDLE" "$PROJECT_DIR/"
    echo "✅ 已复制到项目目录"

    # 设置可执行权限
    chmod +x "$PROJECT_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"

    echo ""
    echo "🚀 运行应用：open $PROJECT_DIR/$APP_NAME.app"
else
    echo "❌ 编译失败"
    exit 1
fi