#!/bin/bash

# 自定义颜色和样式变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'  # 还原颜色

# 图标定义
INFO_ICON="ℹ️"
SUCCESS_ICON="✅"
WARNING_ICON="⚠️"
ERROR_ICON="❌"

# 信息显示函数
log_info() { echo -e "${BLUE}${INFO_ICON} ${1}${NC}"; }
log_success() { echo -e "${GREEN}${SUCCESS_ICON} ${1}${NC}"; }
log_warning() { echo -e "${YELLOW}${WARNING_ICON} ${1}${NC}"; }
log_error() { echo -e "${RED}${ERROR_ICON} ${1}${NC}"; }

# 强制终止任何正在运行的 apt 进程
kill_apt_processes() {
    local apt_processes=$(pgrep -f apt)

    if [ -n "$apt_processes" ]; then
        log_info "检测到正在运行的 apt 进程，正在终止..."
        for pid in $apt_processes; do
            sudo kill -9 $pid
            log_info "已终止进程: $pid"
        done
    fi
}

# 初始化所有环境
initialize_environment() {
    clear

    log_info "显示 BlockMesh logo..."
    wget -q -O loader.sh https://raw.githubusercontent.com/DiscoverMyself/Ramanode-Guides/main/loader.sh && chmod +x loader.sh && ./loader.sh
    curl -s https://raw.githubusercontent.com/ziqing888/logo.sh/refs/heads/main/logo.sh | bash
    sleep 2

    # 安装 Docker
    log_info "检查 Docker 是否已安装..."
    if ! command -v docker &> /dev/null; then
        log_info "安装 Docker..."
        kill_apt_processes  # 确保没有 apt 进程运行
        sudo apt-get install -y ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        kill_apt_processes  # 确保没有 apt 进程运行
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        if [ $? -ne 0 ]; then
            log_error "Docker 安装失败，请检查网络连接或权限。"
            exit 1
        fi
        log_success "Docker 安装完成。"
    else
        log_success "Docker 已安装，跳过..."
    fi

    # 安装 Docker Compose
    log_info "安装 Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    if [ $? -ne 0 ]; then
        log_error "Docker Compose 安装失败。"
        exit 1
    fi
    log_success "Docker Compose 安装完成."

    # 清理旧文件
    rm -rf blockmesh-cli.tar.gz target
    # 创建用于解压的目标目录
    mkdir -p target/release

    # 下载并解压最新版 BlockMesh CLI
    log_info "下载并解压 BlockMesh CLI..."
    #latest_release_url=$(curl -s https://api.github.com/repos/block-mesh/block-mesh-monorepo/releases/latest | jq -r '.assets[] | select(.name | contains("blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz")) | .browser_download_url')
    #wget "$latest_release_url" -O blockmesh-cli.tar.gz
    #tar -xzf blockmesh-cli.tar.gz -C target/release --strip-components=3
    curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.358/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
    tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release
    # 验证解压结果
    if [[ ! -f target/release/blockmesh-cli ]]; then
        echo "错误：未找到 blockmesh-cli 可执行文件于 target/release。退出..."
        exit 1
    fi
    rm -f blockmesh-cli.tar.gz
    log_success "BlockMesh CLI 下载并解压完成."
}

# 注册用户并等待确认
register_and_wait_for_confirmation() {
    log_info "注册 BlockMesh 用户并等待确认..."

    # 发送注册请求
    curl 'https://app.blockmesh.xyz/register' \
        -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
        -H 'accept-language: zh-CN,zh;q=0.9' \
        -H 'cache-control: max-age=0' \
        -H 'content-type: application/x-www-form-urlencoded' \
        -H 'origin: https://app.blockmesh.xyz' \
        -H 'referer: https://app.blockmesh.xyz/register?invite_code=1371130120' \
        --data-raw "email=$email&password=$password&password_confirm=$password&invite_code=1371130120"

    if [ $? -ne 0 ]; then
        log_error "注册失败，请检查网络连接。"
        exit 1
    fi

    log_success "邮箱确认成功."
}

# 运行 Docker 容器
run_docker_container() {
    log_info "为 BlockMesh CLI 创建 Docker 容器..."

    # 打印要传入的环境变量，以便调试
    echo "传递给 Docker 的邮箱: $email"
    echo "传递给 Docker 的密码: $password"

    # 检查是否存在同名的正在运行的容器
    if [ "$(sudo docker ps -aq -f name=blockmesh-cli-container)" ]; then
        log_warning "检测到已有同名容器，正在移除旧容器..."
        sudo docker rm -f blockmesh-cli-container
    fi

    # 启动 Docker 容器
    sudo docker run -dit \
    	--restart always \
        --name blockmesh-cli-container \
        -v $(pwd)/target/release:/app \
        -e EMAIL="$email" \
        -e PASSWORD="$password" \
        --workdir /app \
        ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"

    # 检查容器启动是否成功
    docker_return_code=$?
    if [ $docker_return_code -ne 0 ]; then
        log_error "Docker 容器启动失败，请检查 Docker 是否正常运行。"
        exit 1
    fi

    log_success "Docker 容器已成功运行 BlockMesh CLI."
}

# 主函数
main() {
    # 初始化环境
    initialize_environment

    # 获取用户登录信息
    email=\$1  
    password=\$2  

    # 打印传入的参数
    echo "邮箱地址: $email"
    echo "密码: $password"

    # 运行 Docker 容器
    run_docker_container
}

# 判断是否传入命令行参数
if [ $# -eq 0 ]; then
    # 值守执行
    # 主循环
    while true; do
        clear
        echo -e "🚀 BlockMesh CLI 菜单"
        echo -e "1) 初始化环境,输入登录信息"
        echo -e "2) 注册用户并等待确认"
        echo -e "3) 启动 BlockMesh"
        echo -e "4) 退出"
        read -rp "请输入您的选择: " choice
        case $choice in
            1) 
                initialize_environment
                read -p "请输入您的 BlockMesh 邮箱: " email
                read -s -p "请输入您的 BlockMesh 密码: " password
                echo
                 ;;
            2) register_and_wait_for_confirmation ;;
            3) run_docker_container ;;
            4) log_info "退出脚本"; break ;;
            *) log_warning "无效的选择，请重试。" ;;
        esac
        read -rp "按 Enter 键返回菜单..."
    done
else
    # 自动执行
    main "$@"
fi
