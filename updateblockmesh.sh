#!/bin/bash
# 停止容器
docker stop blockmesh-cli-container
# 清理旧文件
rm -rf blockmesh-cli.tar.gz target

# 创建用于解压的目标目录
mkdir -p target/release

# 下载并解压最新版 BlockMesh CLI
echo "下载并解压 BlockMesh CLI..."

latest_release_url=$(curl -s https://api.github.com/repos/block-mesh/block-mesh-monorepo/releases/latest | jq -r '.assets[] | select(.name | contains("blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz")) | .browser_download_url')
echo $latest_release_url
wget "$latest_release_url" -O blockmesh-cli.tar.gz
tar -xzf blockmesh-cli.tar.gz -C target/release --strip-components=3

# 验证解压结果
if [[ ! -f target/release/blockmesh-cli ]]; then
    echo "错误：未找到 blockmesh-cli 可执行文件于 target/release。退出..."
    exit 1
fi
touch target/release/blockmesh-cli

# 重启容器
docker restart blockmesh-cli-container

echo "已更新程序并重启容器。"
