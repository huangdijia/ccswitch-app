#!/bin/bash

# 修复并运行 CCSwitch

set -e

echo "🔧 修复并运行 CCSwitch..."
echo ""

PROJECT_DIR="/Users/hdj/github/huangdijia/ccswitch-app/CCSwitch"
APP_BUNDLE="$PROJECT_DIR/CCSwitch.app"

# 1. 检查编译
if [ ! -f "$APP_BUNDLE/Contents/MacOS/CCSwitch" ]; then
    echo "📦 需要编译..."
    ./compile_swift.sh
fi

# 2. 修复 Info.plist
echo "📝 修复 Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>CCSwitch</string>
	<key>CFBundleIdentifier</key>
	<string>com.cccode.switch</string>
	<key>CFBundleName</key>
	<string>CCSwitch</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>LSMinimumSystemVersion</key>
	<string>11.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSSupportsAutomaticGraphicsSwitching</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
EOF

# 3. 移除隔离属性
echo "🔓 移除安全隔离属性..."
xattr -d com.apple.quarantine "$APP_BUNDLE" 2>/dev/null || true

# 4. 设置执行权限
chmod +x "$APP_BUNDLE/Contents/MacOS/CCSwitch"

# 5. 创建配置目录
echo "📁 创建配置目录..."
mkdir -p ~/.ccswitch
mkdir -p ~/.claude

# 6. 创建默认配置（如果不存在）
if [ ! -f ~/.ccswitch/ccs.json ]; then
    echo "📄 创建默认配置..."
    cat > ~/.ccswitch/ccs.json << 'EOF'
{
  "version": 1,
  "current": "anthropic",
  "vendors": [
    {
      "id": "anthropic",
      "displayName": "Anthropic",
      "env": {
        "ANTHROPIC_MODEL": "claude-3-5-sonnet"
      }
    },
    {
      "id": "deepseek",
      "displayName": "DeepSeek",
      "env": {
        "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
        "ANTHROPIC_MODEL": "deepseek-chat"
      }
    }
  ]
}
EOF
fi

# 7. 运行应用
echo ""
echo "🚀 启动应用..."
echo ""
echo "使用以下方法之一运行："
echo ""
echo "方法 1 - 直接运行（推荐）："
echo "  $APP_BUNDLE/Contents/MacOS/CCSwitch"
echo ""
echo "方法 2 - 使用 open 命令："
echo "  open $APP_BUNDLE"
echo ""
echo "方法 3 - 双击应用"
echo ""

# 直接运行应用
"$APP_BUNDLE/Contents/MacOS/CCSwitch" &

echo "✅ 应用已在后台启动"
echo ""
echo "检查状态栏中的 'CC' 图标"
echo ""
echo "如果菜单项仍然是灰色，请在系统偏好设置 > 安全性与隐私中允许应用运行"