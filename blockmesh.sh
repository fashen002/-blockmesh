#!/bin/bash

# 清理旧文件
rm -rf blockmesh-cli.tar.gz target

# 如果未安装 Docker，则进行安装
if ! command -v docker &> /dev/null; then
    echo "正在安装 Docker..."
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
else
    echo "Docker 已安装，跳过安装步骤..."
fi

# 安装 Docker Compose
echo "正在安装 Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 创建用于解压的目标目录
mkdir -p target/release

# 下载并解压最新版 BlockMesh CLI
    # 下载并解压最新版 BlockMesh CLI
    log_info "下载并解压 BlockMesh CLI..."
    latest_release_url=$(curl -s https://api.github.com/repos/block-mesh/block-mesh-monorepo/releases/latest | jq -r '.assets[] | select(.name | contains("blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz")) | .browser_download_url')
    wget "$latest_release_url" -O blockmesh-cli.tar.gz
	tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release

	# 验证解压结果
	if [[ ! -f target/release/blockmesh-cli ]]; then
		echo "错误：未找到 blockmesh-cli 可执行文件于 target/release。退出..."
		exit 1
	fi


email=\$1  
password=\$2  

# 使用 BlockMesh CLI 创建 Docker 容器
echo "为 BlockMesh CLI 创建 Docker 容器..."
docker run -it --rm \
    --name blockmesh-cli-container \
    -v $(pwd)/target/release:/app \
    -e EMAIL="$email" \
    -e PASSWORD="$password" \
    --workdir /app \
    ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"
	
	
