@echo off
REM UniversityMarking 系统服务安装脚本
REM 用于手动安装和配置系统锁定服务

echo UniversityMarking 系统服务安装程序
echo =====================================

REM 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 需要管理员权限才能安装服务
    echo 请以管理员身份运行此脚本
    pause
    exit /b 1
)

echo 正在检查服务状态...

REM 检查服务是否已存在
sc query "UniversityMarkingLockService" >nul 2>&1
if %errorlevel% equ 0 (
    echo 服务已存在，正在停止...
    sc stop "UniversityMarkingLockService"
    timeout /t 2 >nul
    
    echo 正在删除旧服务...
    sc delete "UniversityMarkingLockService"
    timeout /t 2 >nul
)

echo 正在创建系统服务...

REM 创建服务
sc create "UniversityMarkingLockService" binPath= "%~dp0service\main.exe" start= manual DisplayName= "UniversityMarking考试系统锁定服务"

if %errorlevel% neq 0 (
    echo 错误: 服务创建失败
    pause
    exit /b 1
)

echo 正在设置服务描述...
sc description "UniversityMarkingLockService" "UniversityMarking考试系统锁定服务 - 提供系统级别的键盘和鼠标锁定功能"

echo 正在设置服务恢复选项...
REM 设置服务失败后的恢复行为
sc failure "UniversityMarkingLockService" reset= 86400 actions= restart/5000/restart/10000/restart/20000

echo.
echo 服务安装完成！
echo 服务名称: UniversityMarkingLockService
echo 显示名称: UniversityMarking考试系统锁定服务
echo 启动类型: 手动
echo.
echo 您可以通过以下方式管理服务:
echo - 使用 services.msc 打开服务管理器
echo - 使用 sc start/stop/query 命令
echo - 通过主程序自动启动服务
echo.

REM 检查服动状态
echo 检查服务安装状态:
sc query "UniversityMarkingLockService"

echo.
echo 按任意键继续...
pause >nul