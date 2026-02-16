# 快速开始指南

> 5 分钟完成 Shiroi 自动部署配置

## 1️⃣ 服务器准备（2 分钟）

```bash
# SSH 登录服务器
ssh root@your-server

# 安装依赖（如果还没有）
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
npm install -g pnpm pm2

# 创建目录和配置
mkdir -p ~/Shiroi
nano ~/Shiroi/.env
```

在 `.env` 中添加：
```bash
NODE_ENV=production
PORT=2323
NEXT_PUBLIC_API_URL=https://your-api.com
NEXT_PUBLIC_GATEWAY_URL=https://your-api.com
```

保存退出（Ctrl+X, Y, Enter）

---

## 2️⃣ GitHub 配置（2 分钟）

### A. 获取 GitHub Token

1. 访问 https://github.com/settings/tokens
2. **Generate new token (classic)**
3. 勾选 `repo` 权限
4. 生成并**复制** token

### B. Fork 并配置 Secrets

1. Fork 本仓库
2. 进入 **Settings** → **Secrets** → **Actions**
3. 添加以下 secrets：

```
HOST = 你的服务器 IP
USER = root
PORT = 22
PASSWORD = 你的 SSH 密码（或使用 KEY）
GH_PAT = 刚才复制的 GitHub Token
```

---

## 3️⃣ 启用并部署（1 分钟）

```bash
# 克隆你 fork 的仓库
git clone https://github.com/YOUR_USERNAME/shiroi-deploy-action
cd shiroi-deploy-action

# 运行初始化脚本
bash init.sh

# 推送触发部署
git push
```

---

## 4️⃣ 查看结果

1. GitHub：**Actions** 标签查看构建进度
2. 服务器：
   ```bash
   pm2 logs Shiro
   ```

---

## ✅ 完成！

访问 `http://your-server:2323` 查看你的 Shiroi 博客。

---

## 🔧 常见问题

**Q: 构建失败，提示找不到仓库？**
A: 检查 GH_PAT 是否有访问 innei-dev/shiroi 的权限

**Q: 部署失败，提示 .env 不存在？**
A: 确保在服务器上创建了 `~/Shiroi/.env` 文件

**Q: 服务启动失败？**
A: 运行 `pm2 logs Shiro` 查看错误日志

**Q: 如何更新？**
A: Shiroi 有新提交时会自动部署，或手动触发：
```bash
echo "update" >> build_hash
git add build_hash && git commit -m "trigger" && git push
```

---

完整文档：[README-NEW.md](./README-NEW.md)
