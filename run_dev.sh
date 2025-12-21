#!/bin/bash

# 开发运行脚本 - 禁用安全检查

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/CCSwitch"

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
open "$PROJECT_DIR/CCSwitch.app"