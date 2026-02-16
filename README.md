# Shiroi Deploy to Remote Server Workflow

这是一个利用 GitHub Action 去构建 Shiroi 然后部署到远程服务器的工作流。

## Why?

Shiroi 是 [Shiro](https://github.com/Innei/Shiro) 的闭源开发版本。

开源版本提供了预构建的 Docker 镜像或者编译产物可直接使用，但是闭源版本并没有提供。

因为 Next.js build 需要大量内存，很多服务器并吃不消这样的开销。

因此这里提供利用 GitHub Action 去完成构建然后推送到服务器。

你可以使用定时任务去定时更新 Shiroi。

## 特性

- ✅ **智能构建**：只在 Shiroi 有更新时触发构建，避免重复构建
- ✅ **云端构建**：在 GitHub Actions 完成构建，节省服务器资源
- ✅ **单一配置**：环境变量从服务器读取，无需在 GitHub 重复配置
- ✅ **版本管理**：保留最近 3 个版本，支持快速回滚
- ✅ **零停机部署**：PM2 自动重启，不影响服务

## How to

开始之前，你的服务器首先需要安装 Node.js, npm, pnpm, pm2。

```sh
# 安装 Node.js 20+
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 安装 pnpm 和 pm2
npm i -g pnpm pm2
```

在你的服务器家目录，新建 `Shiroi` 目录（注意大小写），然后新建 `.env` 填写你的变量。

```bash
mkdir -p ~/Shiroi
nano ~/Shiroi/.env
```

填写内容（**构建时会自动从服务器读取这个文件**）：

```bash
# Env from https://github.com/innei-dev/Shiroi/blob/main/.env.template
NEXT_PUBLIC_API_URL=https://your-api.com/api/v2
NEXT_PUBLIC_GATEWAY_URL=https://your-api.com

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=

## Clerk
CLERK_SECRET_KEY=

NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/

TMDB_API_KEY=

GH_TOKEN=
```

Fork 此项目，然后你需要填写下面的信息。

## Secrets

进入你 fork 的仓库 → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

需要配置的 Secrets：

- `HOST` 服务器地址
- `USER` 服务器用户名
- `PASSWORD` 服务器密码
- `PORT` 服务器 SSH 端口（默认 22）
- `KEY` 服务器 SSH Key（可选，密码 key 二选一）
- `GH_PAT` 可访问 Shiroi 仓库的 Github Token

### Github Token

1. 你的账号可以访问 Shiroi 仓库。
2. 进入 [tokens](https://github.com/settings/tokens) - Personal access tokens - Tokens (classic) - Generate new token - Generate new token (classic)
3. 勾选 `repo` 权限
4. 生成并复制 token，填入 `GH_PAT` secret

![](https://github.com/innei-dev/shiroi-deploy-action/assets/41265413/e55d32cb-bd30-46b7-a603-7d00b3f8a413)

## 启动部署

### 方法 1：运行初始化脚本

```bash
git clone https://github.com/YOUR_USERNAME/shiroi-deploy-action
cd shiroi-deploy-action
bash init.sh
```

### 方法 2：手动初始化

```bash
echo "init" > build_hash
git add build_hash
git commit -m "Initialize deployment"
git push
```

推送后会自动触发第一次构建和部署。

## 工作流程

```
1. 检测 Shiroi 更新（对比 commit hash）
   ↓
2. 从服务器下载 .env 文件
   ↓
3. GitHub Actions 构建 Next.js
   ↓
4. 上传构建产物到服务器
   ↓
5. 服务器安装生产依赖
   ↓
6. PM2 重启服务（零停机）
   ↓
7. 清理旧版本（保留最近 3 个）
```

**构建产物存储在**：`~/Shiroi/releases/<版本号>/`

**当前运行版本**：`~/Shiroi/current` （符号链接）

## 常见操作

### 手动触发构建

**方法 1**：在 GitHub Actions 页面点击 **Run workflow**

**方法 2**：推送更新
```bash
echo "trigger" >> build_hash
git add build_hash && git commit -m "trigger" && git push
```

### 修改环境变量

```bash
# 在服务器上修改
ssh root@your-server
nano ~/Shiroi/.env
# 修改后保存

# 触发新构建（会自动读取新的 .env）
```

**注意**：`NEXT_PUBLIC_*` 变量在构建时内联到代码中，修改后需要重新构建。

### 查看日志

```bash
# PM2 状态
pm2 status Shiro

# 实时日志
pm2 logs Shiro

# 查看错误日志
pm2 logs Shiro --err --lines 50
```

### 版本回滚

```bash
ssh root@your-server
cd ~/Shiroi

# 查看可用版本
ls releases/

# 回滚到指定版本（例如 240）
rm -f current
ln -sf releases/240 current

# 重启服务
export SHIROI_WORKDIR=~/Shiroi/releases/240
pm2 restart ecosystem.config.cjs --update-env
```

## Technical Details

### 目录结构

```
~/Shiroi/
├── .env                    # 环境变量配置（构建时会下载）
├── ecosystem.config.cjs    # PM2 配置（自动生成）
├── logs/                   # PM2 日志目录
├── releases/               # 版本目录
│   ├── 240/
│   ├── 241/
│   └── 242/
└── current -> releases/242 # 当前版本（符号链接）
```

### 部署流程改进

相比旧版本的主要改进：

1. **环境变量管理**：从服务器读取 `.env`，无需在 GitHub Secrets 重复配置
2. **依赖处理**：移除 workspace 依赖，在服务器上安装生产依赖
3. **智能构建**：只在 Shiroi 有更新时构建，避免重复
4. **版本管理**：使用符号链接，支持快速回滚
5. **安全性**：日志已脱敏，不输出敏感路径

### 关于 Sharp

Next.js 在生产环境需要 sharp 来优化图片。如果遇到 sharp 相关警告：

```sh
npm i -g sharp
```

参考：https://nextjs.org/docs/messages/sharp-missing-in-production

## Tips

为了让 PM2 在服务器重启之后能够还原进程。可以使用：

```sh
pm2 startup
pm2 save
```

## 故障排除

**Q: 构建失败，提示找不到 Shiroi 仓库**
A: 检查 `GH_PAT` 是否有访问 `innei-dev/shiroi` 的权限

**Q: 部署失败，提示 .env 不存在**
A: 确保在服务器创建了 `~/Shiroi/.env` 文件（注意大小写）

**Q: 服务启动失败**
A: 查看 PM2 日志 `pm2 logs Shiro --err`

**Q: API URL 未生效**
A: 修改服务器 `.env` 后需要触发新构建

## 相关文档

- [快速开始指南](./QUICKSTART.md) - 5 分钟完成部署
- [迁移指南](./MIGRATION.md) - 从旧版本迁移

## License

MIT
