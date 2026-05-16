#!/bin/bash
# ArkTS 项目编译脚本 - macOS/Linux
# 执行依赖安装和编译

set -e

print_green() {
    echo -e "\033[32m$1\033[0m"
}

print_red() {
    echo -e "\033[31m$1\033[0m"
}

print_green "1. 安装依赖..."
if ! ohpm install --all --registry https://ohpm.openharmony.cn/ohpm/ --strict_ssl true; then
    print_red "❌ 依赖安装失败"
    exit 1
fi

print_green "2. 编译项目..."
if ! hvigorw assembleApp; then
    print_red "❌ 编译失败"
    exit 1
fi

print_green "✅ 编译成功完成"
