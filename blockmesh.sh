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




# 初始化所有环境
initialize_environment() {
	# 设置非交互式前端
	export DEBIAN_FRONTEND=noninteractive

	# 预配置包以避免交互式提示
	echo 'libc6 libraries/restart-without-asking boolean true' | sudo debconf-set-selections
	echo 'grub-pc grub-pc/install_devices_empty boolean true' | sudo debconf-set-selections

	# 更新系统包列表
	log_info "更新系统包列表..."
	if sudo apt-get update -y; then
		log_success "包列表更新成功"
	else
		log_error "包列表更新失败"
		exit 1
	fi

	# 升级系统并避免交互提示
	log_info "开始升级系统..."
	if sudo apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --with-new-pkgs; then
		log_success "系统升级成功"
	else
		log_error "系统升级失败"
		exit 1
	fi
	
    log_info "显示 BlockMesh logo..."
    wget -O loader.sh https://raw.githubusercontent.com/DiscoverMyself/Ramanode-Guides/main/loader.sh && chmod +x loader.sh && ./loader.sh
    curl -s https://raw.githubusercontent.com/ziqing888/logo.sh/refs/heads/main/logo.sh | bash
    sleep 2

    # 下载和解压 BlockMesh CLI
    log_info "下载并解压 BlockMesh CLI..."
    curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.316/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
    tar -xzf blockmesh-cli.tar.gz -C ./
    if [ $? -ne 0 ]; then
        log_error "BlockMesh CLI 下载或解压失败，请检查网络连接。"
        exit 1
    fi
    rm -f blockmesh-cli.tar.gz
    log_success "BlockMesh CLI 下载并解压完成。"
}

# 用户输入
get_user_credentials() {
    email=\$1
    password=\$2
    if [[ -z "$email" || -z "$password" ]]; then
        log_warning "缺少登录信息。"
        exit 1
    fi
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
        -H 'sec-ch-ua: "Google Chrome";v="123", "Not:A-Brand";v="8", "Chromium";v="123"' \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'sec-ch-ua-platform: "Windows"' \
        -H 'sec-fetch-dest: document' \
        -H 'sec-fetch-mode: navigate' \
        -H 'sec-fetch-site: same-origin' \
        -H 'sec-fetch-user: ?1' \
        -H 'upgrade-insecure-requests: 1' \
        -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36' \
        --data-raw "email=$email&password=$password&password_confirm=$password&invite_code=1371130120"

    if [ $? -ne 0 ]; then
        log_error "注册失败，请检查网络连接。"
        exit 1
    fi

    log_success "邮箱确认成功。"
}

# 运行 Docker 容器
run_docker_container() {
    log_info "为 BlockMesh CLI 创建 Docker 容器..."

    # 检查是否存在同名的正在运行的容器
    if [ "$(docker ps -aq -f name=blockmesh-cli-container)" ]; then
        log_warning "检测到已有同名容器，正在移除旧容器..."
        docker rm -f blockmesh-cli-container
    fi

    docker run -dit \
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

    log_success "Docker 容器已成功运行 BlockMesh CLI。"
}

# 主函数
main() {
    # 初始化环境
    initialize_environment

    # 获取用户登录信息
    email=$1
    password=$2

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
        echo -e "1) 初始化环境并输入登录信息"
        echo -e "2) 注册用户并等待确认"
        echo -e "3) 启动 BlockMesh"
        echo -e "4) 退出"
        echo -e "请选择: "
        read -rp "请输入您的选择: " choice
        case $choice in
            1) 
	    	# 初始化环境
    		initialize_environment
                read -rp "请输入您的 BlockMesh 邮箱: " email
                echo "请输入您的 BlockMesh 密码（输入时不会显示在终端）:"
                read -srp "密码: " password
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
    main $1 $2
fi
