# Shiroi 自动部署指南 (Standalone 模式)

自动构建并部署 Shiroi 到远程服务器的 GitHub Actions workflow。

## 🎯 功能特点

- ✅ 自动检测 Shiroi 仓库更新
- ✅ GitHub Actions 云端构建（节省服务器资源）
- ✅ 零停机部署（PM2 reload）
- ✅ 版本管理（保留最近 3 个版本）
- ✅ 一键回滚
- ✅ 支持定时构建（可选）

---

## 📋 前置要求

### 服务器环境

1. **Node.js >= 20**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

2. **pnpm**
   ```bash
   npm install -g pnpm
   ```

3. **PM2**
   ```bash
   npm install -g pm2
   ```

4. **Sharp（可选，用于图片优化）**
   ```bash
   npm install --os=linux --cpu=x64 -g sharp
   ```

### GitHub 配置

需要可以访问 **innei-dev/shiroi** 私有仓库的 GitHub Token。

---

## 🚀 快速开始

### 1. 服务器准备

在服务器上创建目录和配置文件：

```bash
# SSH 登录服务器
ssh root@your-server

# 创建 Shiroi 目录
mkdir -p ~/Shiroi

# 创建 .env 文件
cat > ~/Shiroi/.env << 'EOF'
NODE_ENV=production
PORT=2323

# API 配置（必填）
NEXT_PUBLIC_API_URL=https://your-api.com
NEXT_PUBLIC_GATEWAY_URL=https://your-api.com

# 其他配置...
EOF
```

**重要**：`.env` 文件必须放在 `~/Shiroi/.env`，部署脚本会自动复制到正确位置。

---

### 2. Fork 并配置仓库

#### 2.1 Fork 本仓库

点击右上角 **Fork** 按钮。

#### 2.2 配置 Secrets

进入你 fork 的仓库：**Settings** → **Secrets and variables** → **Actions** → **New repository secret**

添加以下 secrets：

| Secret 名称 | 说明 | 示例 |
|------------|------|------|
| `HOST` | 服务器 IP 地址 | `192.168.1.100` |
| `USER` | SSH 用户名 | `root` |
| `PORT` | SSH 端口 | `22` |
| `PASSWORD` | SSH 密码（二选一） | `your-password` |
| `KEY` | SSH 私钥（二选一） | `-----BEGIN RSA...` |
| `GH_PAT` | GitHub Personal Access Token | `ghp_xxxxx` |

**如何获取 GitHub Token (GH_PAT)**：

1. 进入 [GitHub Settings](https://github.com/settings/tokens)
2. **Personal access tokens** → **Tokens (classic)** → **Generate new token**
3. 勾选权限：
   - ✅ `repo` (全部子权限)
4. 生成并复制 token

---

### 3. 启用 Workflow

1. 进入你 fork 的仓库
2. 点击 **Actions** 标签
3. 点击 **I understand my workflows, go ahead and enable them**
4. 找到 **Build and Deploy Shiroi (Standalone)** workflow
5. 点击 **Enable workflow**

---

### 4. 部署

#### 方式一：推送触发（推荐）

编辑 `build_hash` 文件（随便改点内容），然后提交：

```bash
cd shiroi-deploy-action
echo "trigger" >> build_hash
git add build_hash
git commit -m "Trigger deploy"
git push
```

#### 方式二：手动触发

1. 进入 **Actions** 标签
2. 选择 **Build and Deploy Shiroi (Standalone)**
3. 点击 **Run workflow**
4. 等待构建完成（约 5-10 分钟）

---

## 📁 目录结构

部署后，服务器上的目录结构：

```
~/Shiroi/
├── .env                          # 环境变量配置（手动创建）
├── ecosystem.config.cjs          # PM2 配置（自动生成）
├── current -> releases/123/...   # 当前版本符号链接
├── logs/                         # 日志目录
│   ├── err.log
│   └── out.log
├── releases/                     # 版本目录
│   ├── 123/                      # GitHub run number
│   │   └── standalone/
│   │       ├── apps/web/
│   │       │   ├── server.js
│   │       │   ├── .env          # 从 ~/Shiroi/.env 复制
│   │       │   ├── .next/
│   │       │   └── public/
│   │       └── node_modules/
│   ├── 124/
│   └── 125/
└── .cache/                       # Next.js 缓存
```

---

## 🔄 更新部署

### 自动更新

每次 Shiroi 仓库有新提交时：
1. GitHub Actions 自动检测到更新
2. 触发构建和部署
3. PM2 零停机重启

### 手动触发更新

如果自动更新没触发，可以手动运行：

```bash
# 编辑 build_hash 触发
cd shiroi-deploy-action
echo "$(date)" > build_hash
git add build_hash
git commit -m "Manual trigger"
git push
```

---

## 🛠️ 常用命令

### 查看状态
```bash
pm2 status           # 查看进程状态
pm2 logs Shiro       # 查看实时日志
pm2 monit            # 监控面板
```

### 重启服务
```bash
pm2 restart Shiro    # 重启服务
pm2 reload Shiro     # 零停机重启
```

### 版本回滚

如果新版本有问题，可以快速回滚：

```bash
cd ~/Shiroi/releases
ls -lt               # 查看所有版本

# 回滚到指定版本（例如 123）
rm -f ~/Shiroi/current
ln -sf ~/Shiroi/releases/123/standalone/apps/web ~/Shiroi/current
pm2 restart Shiro
```

---

## 🐛 故障排查

### 1. 部署失败：找不到 .env 文件

**错误**：`❌ 错误：/root/Shiroi/.env 不存在`

**解决**：
```bash
# 确保 .env 在正确位置
ls -la ~/Shiroi/.env

# 如果不存在，创建它
nano ~/Shiroi/.env
```

### 2. 服务启动失败：端口被占用

**错误**：`Error: listen EADDRINUSE: address already in use :::2323`

**解决**：
```bash
# 检查端口占用
lsof -i :2323

# 修改端口（编辑 ecosystem.config.cjs）
nano ~/Shiroi/ecosystem.config.cjs
# 修改 PORT: 2323 为其他端口
```

### 3. 静态资源 404

**原因**：standalone 目录中缺少 static 或 public

**解决**：检查 Shiroi 仓库的 `apps/web/standalone-bundle.sh` 是否正确执行

### 4. API 连接失败

**错误**：`Invalid URL: '/api/v2/...'`

**原因**：`.env` 中的 API URL 配置不正确

**解决**：
```bash
# 检查 .env 配置
cat ~/Shiroi/current/.env | grep API_URL

# 确保是完整 URL（包含 http:// 或 https://）
NEXT_PUBLIC_API_URL=https://your-api.com  # ✅ 正确
NEXT_PUBLIC_API_URL=/api                  # ❌ 错误
```

---

## 📝 高级配置

### 定时自动更新

编辑 `.github/workflows/deploy-new.yml`，取消注释 schedule：

```yaml
on:
  push:
    branches:
      - main
  schedule:
    - cron: '0 3 * * *'  # 每天凌晨 3 点检查更新
  workflow_dispatch:
```

### 部署后钩子

在 GitHub Secrets 中添加 `AFTER_DEPLOY_SCRIPT`：

```bash
# 示例：部署成功后发送通知
curl -X POST "https://your-webhook.com/notify" \
  -H "Content-Type: application/json" \
  -d '{"status": "success", "version": "${{ github.run_number }}"}'
```

### PM2 开机自启

```bash
pm2 startup
pm2 save
```

---

## 🔐 安全建议

1. ✅ 使用 SSH Key 而不是密码
2. ✅ 限制 GitHub Token 的权限（只给 repo 权限）
3. ✅ 定期更换密码和 Token
4. ✅ 使用非 root 用户运行服务
5. ✅ 配置防火墙只开放必要端口

---

## 📚 参考资料

- [Shiroi 官方仓库](https://github.com/innei-dev/shiroi)
- [Next.js Standalone 模式](https://nextjs.org/docs/advanced-features/output-file-tracing)
- [PM2 文档](https://pm2.keymetrics.io/docs/usage/quick-start/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

---

## 🆘 获取帮助

- 提交 Issue：[GitHub Issues](https://github.com/YOUR_USERNAME/shiroi-deploy-action/issues)
- Shiroi 交流群：[加入讨论](https://innei.in)

---

## 📄 许可证

MIT License
