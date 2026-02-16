# 新旧版本部署对比

## 关键差异

| 对比项 | 旧版本 | 新版本 (Standalone) |
|-------|--------|-------------------|
| **构建脚本** | `ci-release-build.sh` | `standalone-bundle.sh` |
| **目录结构** | `standalone/` 平铺 | `standalone/apps/web/` 嵌套 |
| **静态资源** | 手动处理 | 脚本自动复制 |
| **.env 位置** | `~/shiro/.env` | `~/Shiroi/.env` |
| **server.js 位置** | `standalone/server.js` | `standalone/apps/web/server.js` |
| **PM2 cwd** | 软链接到 basedir | 直接指向 standalone 目录 |
| **版本管理** | 按 run_number 目录 | `releases/` 目录 + current 软链接 |

---

## 迁移步骤

如果你之前使用旧版本，需要以下步骤迁移：

### 1. 服务器准备

```bash
# 停止旧版本
pm2 stop Shiro

# 备份旧配置
cp ~/shiro/.env ~/Shiroi.env.backup
cp ~/shiro/ecosystem.config.js ~/ecosystem.config.backup 2>/dev/null || true

# 创建新目录
mkdir -p ~/Shiroi
mv ~/Shiroi.env.backup ~/Shiroi/.env

# 清理旧目录（可选，建议先备份）
# mv ~/shiro ~/shiro.old
```

### 2. 更新 GitHub Actions

```bash
cd shiroi-deploy-action

# 使用新的 workflow
mv .github/workflows/deploy.yml .github/workflows/deploy-old.yml.bak
mv .github/workflows/deploy-new.yml .github/workflows/deploy.yml

# 提交
git add .
git commit -m "Update to new standalone deployment"
git push
```

### 3. 首次部署

触发一次部署：
```bash
echo "$(date)" > build_hash
git add build_hash
git commit -m "Trigger first deploy"
git push
```

---

## 新版本优势

1. ✅ **目录更清晰**：使用 `releases/` 管理版本
2. ✅ **符号链接**：`current` 指向当前版本，方便回滚
3. ✅ **自动清理**：保留最近 3 个版本
4. ✅ **更安全**：.env 独立管理，不在版本目录内
5. ✅ **兼容最新 Shiroi**：适配新的 monorepo 结构

---

## 回滚到旧版本

如果新版本有问题，可以临时回到旧部署：

```bash
# 恢复旧 workflow
cd shiroi-deploy-action
git checkout .github/workflows/deploy.yml
git push

# 服务器上使用旧目录
cd ~/shiro
pm2 start ecosystem.config.js
```
