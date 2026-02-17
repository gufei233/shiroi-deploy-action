#!/bin/bash

BASEDIR="$HOME/Shiroi"
RELEASES_DIR="$BASEDIR/releases"

# 用于存放数字文件夹的数组
folders=()

# 遍历 releases/ 目录下的数字文件夹
for dir in "$RELEASES_DIR"/*/; do
  name=$(basename "$dir")
  if [[ -d "$dir" && "$name" =~ ^[0-9]+$ ]]; then
    folders+=("$name")
  fi
done

if [ ${#folders[@]} -eq 0 ]; then
  echo "错误：releases/ 目录下没有可用的版本"
  exit 1
fi

# 数字文件夹按数字从大到小排序
IFS=$'\n' folders=($(sort -rn <<<"${folders[*]}"))
unset IFS

# 使用 select 构建一个选择菜单
echo "请选择要回滚到的版本："
select folder in "${folders[@]}"; do
  if [ -n "$folder" ]; then
    echo "您选择了版本：$folder"
    break
  else
    echo "无效的选择，请重新选择。"
  fi
done

TARGET_DIR="$RELEASES_DIR/$folder"

# 检查用户所选的文件夹中是否存在 apps/web/server.js
if [ -f "$TARGET_DIR/apps/web/server.js" ]; then
  # 更新 current 符号链接指向目标版本目录
  ln -sf "$TARGET_DIR" "$BASEDIR/current"
  echo "已将 current 链接到 $TARGET_DIR"
  export SHIROI_WORKDIR="$TARGET_DIR"
  pm2 restart "$BASEDIR/ecosystem.config.cjs" --update-env
  echo "Rollback successfully."
else
  echo "错误：所选版本中不存在 apps/web/server.js"
fi
