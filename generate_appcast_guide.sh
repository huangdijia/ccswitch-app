#!/bin/bash

# CCSwitch Sparkle Appcast Generator
# 注意：你需要安装 Sparkle 的 bin 工具才能运行此脚本

# 配置
PROJECT_DIR="CCSwitch"
APPCAST_PATH="appcast.xml"
REPO_URL="https://github.com/huangdijia/ccswitch-mac"
DOWNLOAD_URL_BASE="${REPO_URL}/releases/download"

# 尝试寻找 Sparkle 工具 (SPM 路径)
GENERATE_APPCAST=$(find . -name generate_appcast -type f | head -n 1)

if [ -z "$GENERATE_APPCAST" ]; then
    echo "错误: 未找到 generate_appcast 工具。"
    echo "请确保已通过 SPM 安装了 Sparkle，或者手动指定工具路径。"
    exit 1
fi

echo "正在使用工具: $GENERATE_APPCAST"

# 运行生成
# 假设你的发布包放在 build/deploy 目录下
mkdir -p build/deploy

# 使用说明
echo "--------------------------------------------------"
echo "使用建议:"
echo "1. 将签名的 .zip 包放入 build/deploy 目录"
echo "2. 运行: $GENERATE_APPCAST build/deploy"
echo "3. 脚本会自动更新 $APPCAST_PATH"
echo "--------------------------------------------------"

# 示例命令 (取消注释以运行)
# $GENERATE_APPCAST build/deploy
