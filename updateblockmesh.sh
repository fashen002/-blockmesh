#!/bin/bash

# 从命令行参数获取文件名
filename=\$1

# 日志文件路径
log_file="/root/Goat_bot/log.txt"

# 检查文件是否存在
if [ -e "$filename" ]; then
    # 如果是文件夹，则删除
    if [ -d "$filename" ]; then
        rm -rf "$filename"
        echo "$(date): 文件夹 $filename 被删除" >> "$log_file"
    fi
fi

# 创建新的文本文件
touch "$filename"
echo "$(date): 文件 $filename 被创建" >> "$log_file"
