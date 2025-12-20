#!/bin/bash

# 开发运行脚本 - 禁用安全检查

set -e

PROJECT_DIR="/Users/hdj/github/huangdijia/ccswitch-app/CCSwitch"

echo "🔨 重新编译应用..."

# 重新编译
./compile_swift.sh

echo ""
echo "🔧 配置应用权限..."

# 移除隔离属性（解除 macOS 的安全限制）
xattr -d com.apple.quarantine "$PROJECT_DIR/CCSwitch.app" 2>/dev/null || true

# 临时禁用 Gatekeeper（仅用于开发）
sudo spctl --master-disable 2>/dev/null || echo "⚠️  需要管理员权限来禁用 Gatekeeper"

echo ""
echo "🚀 启动应用..."

# 运行应用
"$PROJECT_DIR/CCSwitch.app/Contents/MacOS/CCSwitch" &

echo ""
echo "✅ 应用已启动！"
echo "📍 查看状态栏中的 'CC' 图标"
echo ""
echo "提示：如果菜单项仍然是灰色，请："
echo "1. 确保 '辅助功能' 权限已授予终端"
echo "2. 或者在系统偏好设置中手动允许应用运行"