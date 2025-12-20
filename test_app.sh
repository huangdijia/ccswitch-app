#!/bin/bash

# 测试应用基本功能

echo "🧪 测试 CCSwitch 应用..."
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/CCSwitch"
APP_BUNDLE="$PROJECT_DIR/CCSwitch.app"

# 检查应用是否存在
if [ ! -f "$APP_BUNDLE/Contents/MacOS/CCSwitch" ]; then
    echo "❌ 应用未找到，请先编译"
    exit 1
fi

echo "📂 应用信息："
echo "  路径: $APP_BUNDLE"
echo "  大小: $(du -sh "$APP_BUNDLE" | cut -f1)"
echo ""

# 检查配置文件
echo "📄 配置文件："
echo "  ~/.ccswitch/ccs.json: $([ -f ~/.ccswitch/ccs.json ] && echo "存在" || echo "不存在（首次运行时会创建）")"
echo "  ~/.claude/settings.json: $([ -f ~/.claude/settings.json ] && echo "存在" || echo "不存在")"
echo ""

echo "🚀 尝试运行应用..."
echo ""

# 移除隔离属性
xattr -d com.apple.quarantine "$APP_BUNDLE" 2>/dev/null || true

# 在新的终端窗口运行应用
osascript -e "tell application \"Terminal\" to do script \"cd $PROJECT_DIR && ./CCSwitch.app/Contents/MacOS/CCSwitch\""

echo ""
echo "✅ 应用已在新终端窗口中启动"
echo ""
echo "请检查："
echo "1. 状态栏是否出现 'CC' 图标"
echo "2. 点击图标后菜单是否正常显示"
echo "3. 菜单项（设置、退出）是否可点击"
echo ""
echo "如果菜单项仍然是灰色，说明 macOS 安全机制阻止了应用"