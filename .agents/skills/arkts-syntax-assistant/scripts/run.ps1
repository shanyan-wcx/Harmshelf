# ArkTS 项目编译脚本 - Windows PowerShell
# 执行依赖安装和编译

$ErrorActionPreference = "Stop"

try {
    Write-Host "1. 安装依赖..." -ForegroundColor Green
    ohpm install --all --registry https://ohpm.openharmony.cn/ohpm/ --strict_ssl true

    Write-Host "2. 编译项目..." -ForegroundColor Green
    hvigorw assembleApp

    Write-Host "✅ 编译成功完成" -ForegroundColor Green
} catch {
    Write-Host "❌ 编译失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
