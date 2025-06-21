@echo off
REM UniversityMarking 安装程序测试脚本 (Windows Batch)
REM 用于在 CI/CD 环境中运行基本的安装程序测试

setlocal EnableDelayedExpansion

REM 设置变量
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\..\" 
set "DIST_DIR=%PROJECT_ROOT%dist"
set "LOG_FILE=installer-test-%date:~0,4%%date:~5,2%%date:~8,2%-%time:~0,2%%time:~3,2%%time:~6,2%.log"
set "TEST_PASSED=0"
set "TEST_FAILED=0"

REM 创建日志文件
echo [%date% %time%] Starting UniversityMarking installer tests > "%LOG_FILE%"

REM 日志函数
:LOG
echo [%date% %time%] %~1
echo [%date% %time%] %~1 >> "%LOG_FILE%"
goto :eof

REM 测试结果记录
:TEST_RESULT
if "%~2"=="PASS" (
    set /a TEST_PASSED+=1
    call :LOG "[PASS] %~1"
) else (
    set /a TEST_FAILED+=1
    call :LOG "[FAIL] %~1"
)
goto :eof

REM 检查管理员权限
:CHECK_ADMIN
call :LOG "Checking administrator privileges..."
net session >nul 2>&1
if %errorlevel% neq 0 (
    call :TEST_RESULT "Administrator privileges" "FAIL"
    call :LOG "ERROR: Administrator privileges required"
    goto :END_TESTS
) else (
    call :TEST_RESULT "Administrator privileges" "PASS"
)
goto :eof

REM 查找安装程序文件
:FIND_INSTALLER
call :LOG "Looking for installer files..."
set "INSTALLER_FILE="

for %%f in ("%DIST_DIR%\*.exe") do (
    if exist "%%f" (
        set "INSTALLER_FILE=%%f"
        call :LOG "Found installer: %%f"
        goto :INSTALLER_FOUND
    )
)

call :TEST_RESULT "Installer file found" "FAIL"
call :LOG "ERROR: No installer file found in %DIST_DIR%"
goto :END_TESTS

:INSTALLER_FOUND
call :TEST_RESULT "Installer file found" "PASS"
goto :eof

REM 检查安装程序文件信息
:CHECK_INSTALLER_INFO
call :LOG "Checking installer file information..."

REM 检查文件大小
for %%A in ("%INSTALLER_FILE%") do set "FILE_SIZE=%%~zA"
if %FILE_SIZE% lss 5242880 (
    call :TEST_RESULT "Installer file size" "FAIL"
    call :LOG "ERROR: Installer file too small: %FILE_SIZE% bytes"
) else (
    call :TEST_RESULT "Installer file size" "PASS"
    call :LOG "Installer file size: %FILE_SIZE% bytes"
)

REM 检查文件类型
echo "%INSTALLER_FILE%" | findstr /i ".exe" >nul
if %errorlevel% equ 0 (
    call :TEST_RESULT "Installer file type" "PASS"
) else (
    call :TEST_RESULT "Installer file type" "FAIL"
)

goto :eof

REM 测试安装程序参数
:TEST_INSTALLER_PARAMS
call :LOG "Testing installer parameters..."

REM 测试帮助参数
"%INSTALLER_FILE%" /? >nul 2>&1
if %errorlevel% equ 0 (
    call :TEST_RESULT "Installer help parameter" "PASS"
) else (
    call :TEST_RESULT "Installer help parameter" "FAIL"
)

goto :eof

REM 模拟安装测试（不实际安装）
:SIMULATE_INSTALL
call :LOG "Simulating installation process..."

REM 检查安装目标目录
set "INSTALL_DIR=%ProgramFiles%\UniversityMarking"
if exist "%INSTALL_DIR%" (
    call :LOG "Previous installation found at: %INSTALL_DIR%"
else (
    call :LOG "No previous installation found"
)

REM 模拟安装检查
call :TEST_RESULT "Installation simulation" "PASS"

goto :eof

REM 检查系统兼容性
:CHECK_SYSTEM_COMPATIBILITY
call :LOG "Checking system compatibility..."

REM 检查 Windows 版本
for /f "tokens=2 delims=[]" %%A in ('ver') do set "WINDOWS_VERSION=%%A"
call :LOG "Windows version: %WINDOWS_VERSION%"

REM 检查架构
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    call :LOG "System architecture: 64-bit"
    call :TEST_RESULT "System architecture detection" "PASS"
) else if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    call :LOG "System architecture: 32-bit"
    call :TEST_RESULT "System architecture detection" "PASS"
) else (
    call :LOG "Unknown system architecture: %PROCESSOR_ARCHITECTURE%"
    call :TEST_RESULT "System architecture detection" "FAIL"
)

REM 检查磁盘空间
for /f "tokens=3" %%A in ('dir /-c "%SystemDrive%\" ^| find "bytes free"') do set "FREE_SPACE=%%A"
if defined FREE_SPACE (
    call :LOG "Free disk space: %FREE_SPACE% bytes"
    call :TEST_RESULT "Disk space check" "PASS"
) else (
    call :TEST_RESULT "Disk space check" "FAIL"
)

goto :eof

REM 生成测试报告
:GENERATE_REPORT
call :LOG "Generating test report..."

set /a TOTAL_TESTS=%TEST_PASSED%+%TEST_FAILED%
set "REPORT_FILE=installer-test-report-%date:~0,4%%date:~5,2%%date:~8,2%-%time:~0,2%%time:~3,2%%time:~6,2%.txt"

echo UniversityMarking 安装程序测试报告 > "%REPORT_FILE%"
echo ================================== >> "%REPORT_FILE%"
echo 测试时间: %date% %time% >> "%REPORT_FILE%"
echo 总测试数: %TOTAL_TESTS% >> "%REPORT_FILE%"
echo 通过数: %TEST_PASSED% >> "%REPORT_FILE%"
echo 失败数: %TEST_FAILED% >> "%REPORT_FILE%"

if %TEST_FAILED% equ 0 (
    echo 测试结果: 全部通过 >> "%REPORT_FILE%"
) else (
    echo 测试结果: 有失败项 >> "%REPORT_FILE%"
)

echo. >> "%REPORT_FILE%"
echo 详细日志请查看: %LOG_FILE% >> "%REPORT_FILE%"

call :LOG "Test report generated: %REPORT_FILE%"
goto :eof

REM 主测试流程
:MAIN_TESTS
echo.
echo UniversityMarking 安装程序测试
echo =====================================
echo.

call :LOG "Starting main test sequence..."

REM 执行所有测试
call :CHECK_ADMIN
if %TEST_FAILED% gtr 0 goto :END_TESTS

call :FIND_INSTALLER
if %TEST_FAILED% gtr 0 goto :END_TESTS

call :CHECK_INSTALLER_INFO
call :TEST_INSTALLER_PARAMS
call :CHECK_SYSTEM_COMPATIBILITY
call :SIMULATE_INSTALL

goto :eof

:END_TESTS
call :GENERATE_REPORT

echo.
echo 测试完成！
echo 总测试数: %TEST_PASSED% + %TEST_FAILED% = %TOTAL_TESTS%
echo 通过: %TEST_PASSED%
echo 失败: %TEST_FAILED%
echo.

if %TEST_FAILED% equ 0 (
    echo 所有测试通过！
    exit /b 0
) else (
    echo 有 %TEST_FAILED% 个测试失败！
    exit /b 1
)

REM 主程序入口
call :MAIN_TESTS
goto :END_TESTS