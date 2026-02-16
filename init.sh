#!/bin/bash
# Shiroi 部署初始化脚本

set -e

echo "🚀 Shiroi 自动部署初始化"
echo "=========================="
echo ""

# 检查 git
if ! command -v git &> /dev/null; then
    echo "❌ 错误：未安装 git"
    exit 1
fi

# 初始化 build_hash
if [ ! -f "build_hash" ]; then
    echo "init" > build_hash
    echo "✓ 创建 build_hash 文件"
else
    echo "✓ build_hash 文件已存在"
fi

# 检查 workflow
if [ ! -f ".github/workflows/deploy.yml" ]; then
    if [ -f ".github/workflows/deploy-new.yml" ]; then
        mv .github/workflows/deploy-new.yml .github/workflows/deploy.yml
        echo "✓ 启用新版 workflow"
    else
        echo "⚠️  警告：未找到 workflow 文件"
    fi
fi

echo ""
echo "📋 接下来的步骤："
echo "1. 配置 GitHub Secrets (HOST, USER, PASSWORD/KEY, PORT, GH_PAT)"
echo "2. 在服务器上创建 ~/Shiroi/.env 文件"
echo "3. 提交并推送代码触发部署"
echo ""
echo "准备好了吗？(y/n)"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    git add build_hash .github/workflows/
    git commit -m "Initialize Shiroi deployment" || true
    echo ""
    echo "✅ 初始化完成！"
    echo "现在运行 'git push' 来推送代码"
else
    echo "已取消"
fi
