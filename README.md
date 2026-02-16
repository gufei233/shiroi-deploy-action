# Shiroi 自动部署工具

> 一键部署 Shiroi 博客到你的服务器，基于 GitHub Actions 自动构建和部署。

## ✨ 特性

- 🚀 **全自动构建**：在 GitHub Actions 云端构建，节省服务器资源
- 📦 **智能部署**：仅在 Shiroi 有更新时触发构建
- 🔒 **安全可靠**：从服务器直接获取环境变量，单一配置源
- 🔄 **版本管理**：保留最近 3 个版本，支持快速回滚
- ⚡ **零停机**：PM2 cluster 模式，自动重启

## 📋 前置要求

### 服务器环境
- Node.js 20+
- pnpm（全局安装）
- PM2（全局安装）
- SSH 访问权限

### GitHub
- Fork 本仓库
- 配置 GitHub Secrets（见下方）

## 🚀 快速开始

完整步骤请参考 **[快速开始指南](./QUICKSTART.md)**（5 分钟完成配置）

### 简要步骤

#### 1. 服务器准备
```bash
# 安装依赖
npm install -g pnpm pm2

# 创建配置
mkdir -p ~/Shiroi
nano ~/Shiroi/.env
```

在 `.env` 中添加：
```bash
NEXT_PUBLIC_API_URL=https://your-api.com/api/v2
NEXT_PUBLIC_GATEWAY_URL=https://your-api.com
```

#### 2. GitHub 配置

Fork 本仓库，然后配置 Secrets：
- `HOST` - 服务器 IP
- `USER` - SSH 用户名
- `PORT` - SSH 端口
- `PASSWORD` 或 `KEY` - SSH 认证
- `GH_PAT` - GitHub Token

#### 3. 启用部署

```bash
git clone https://github.com/YOUR_USERNAME/shiroi-deploy-action
cd shiroi-deploy-action
bash init.sh
```

## 📊 工作流程

```
检测更新 → 下载 .env → 云端构建 → 部署到服务器 → PM2 重启
```

1. **智能检测**：对比 Shiroi commit hash，仅在有更新时构建
2. **环境变量**：从服务器 `~/Shiroi/.env` 下载到构建环境
3. **云端构建**：GitHub Actions 完成 Next.js 构建（节省服务器资源）
4. **服务器部署**：上传构建产物 → 安装依赖 → PM2 重启

## 🛠️ 常见操作

### 手动触发构建

**方法 1**：GitHub Actions 页面点击 **Run workflow**

**方法 2**：推送代码触发
```bash
echo "trigger" >> build_hash
git add build_hash && git commit -m "trigger" && git push
```

### 修改环境变量

```bash
# 1. 在服务器上修改
ssh root@your-server
nano ~/Shiroi/.env
# 保存退出

# 2. 触发新构建（会自动读取新的 .env）
# GitHub Actions 或手动 git push
```

**注意**：环境变量在**构建时**内联到代码中，修改后需要重新构建。

### 版本回滚

```bash
ssh root@your-server
cd ~/Shiroi

# 查看可用版本
ls releases/

# 回滚到指定版本（例如 240）
rm -f current && ln -sf releases/240 current

# 重启服务
export SHIROI_WORKDIR=~/Shiroi/releases/240
pm2 restart ecosystem.config.cjs --update-env
```

### 查看日志

```bash
# PM2 状态
pm2 status Shiro

# 实时日志
pm2 logs Shiro

# 错误日志
pm2 logs Shiro --err --lines 50
```

## 🐛 常见问题

### 构建失败

**Q: 提示找不到 Shiroi 仓库**
A: 检查 `GH_PAT` secret 是否有访问 `innei-dev/shiroi` 的权限

**Q: pnpm 安装失败**
A: 已自动处理 lockfile 问题，应该能正常安装

### 部署失败

**Q: 提示 .env 不存在**
A: 确保在服务器上创建了 `~/Shiroi/.env` 文件

**Q: 模块找不到错误**
A: 服务器上依赖安装失败，查看部署日志的 `pnpm install` 步骤

**Q: 服务启动失败**
A: 查看 PM2 日志：`pm2 logs Shiro --err --lines 50`

### 环境变量问题

**Q: API URL 未生效**
A:
1. 确认服务器 `~/Shiroi/.env` 中有正确的配置
2. 触发新的 GitHub Actions 构建
3. 等待部署完成

## 📚 技术细节

### 目录结构

```
~/Shiroi/
├── .env                    # 环境变量配置
├── ecosystem.config.cjs    # PM2 配置（自动生成）
├── logs/                   # PM2 日志
├── releases/               # 版本目录
│   ├── 240/
│   ├── 241/
│   └── 242/
└── current -> releases/242 # 当前版本符号链接
```

### 部署流程

```yaml
GitHub Actions:
  1. 检测 Shiroi 更新（对比 commit hash）
  2. 通过 SCP 下载服务器的 .env 文件
  3. 使用 .env 构建 Next.js 项目
  4. 打包 standalone 产物（不含 node_modules）
  5. 上传到服务器 /tmp/shiroi

服务器部署：
  6. 解压到 ~/Shiroi/releases/<版本号>/
  7. 运行 pnpm install --prod 安装依赖
  8. 复制 .env 到运行目录
  9. 更新 current 符号链接
  10. PM2 重启服务（零停机）
  11. 清理旧版本（保留最近 3 个）
```

### 安全措施

- ✅ GitHub Secrets 加密存储
- ✅ SSH 连接支持密钥或密码认证
- ✅ 构建日志不输出敏感信息
- ✅ .env 文件仅在服务器和构建环境可见
- ✅ 服务器路径已脱敏

## 📖 相关文档

- [快速开始指南](./QUICKSTART.md) - 5 分钟完成配置
- [迁移指南](./MIGRATION.md) - 从旧版本迁移

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 License

MIT

---

**Powered by GitHub Actions | Built with ❤️ for Shiroi**
