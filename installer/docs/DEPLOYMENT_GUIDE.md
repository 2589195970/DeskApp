# UniversityMarking 系统部署指南

## 概述

本文档提供 UniversityMarking 考试监考系统的完整部署指南，包括安装程序构建、分发和部署流程。

## 系统架构

UniversityMarking 系统由以下组件构成：

### 核心组件
1. **Electron_App** - 主用户界面（Vue.js + Electron）
2. **LockSys_Python** - 系统锁定服务（Python + Flask）
3. **ChangeConfigUtil** - 配置工具（Python + Tkinter）
4. **Start_Bat** - 系统启动脚本

### 安装程序组件
- **Inno Setup 安装脚本** - 创建 Windows 安装程序
- **GitHub Actions 工作流** - 自动化构建和发布
- **测试脚本** - 安装程序验证工具

## 部署环境要求

### 开发环境
- **操作系统：** Windows 10/11 或 macOS/Linux（开发）
- **Node.js：** 16.x 或更高版本
- **Python：** 3.8+ 
- **Git：** 最新版本

### 构建环境
- **操作系统：** Windows Server 2019+ 或 Windows 10/11
- **Inno Setup：** 6.2.2 或更高版本
- **管理员权限：** 构建和测试安装程序时需要

### 目标环境（用户设备）
- **操作系统：** Windows Vista 或更高版本
- **架构：** x86 或 x64
- **内存：** 至少 2GB
- **磁盘空间：** 至少 100MB
- **权限：** 管理员权限（安装时）

## 构建流程

### 1. 环境准备

```bash
# 克隆仓库
git clone <repository-url>
cd UniversityMarking_DeskApp

# 安装 Node.js 依赖
cd Electron_App
npm install
cd ..

# 安装 Python 依赖
pip install -r LockSys_Python/requirements.txt
pip install pyinstaller
```

### 2. 本地构建

#### 手动构建

```bash
# 执行构建准备脚本
node installer/build-scripts/prepare-build.js

# 使用 Inno Setup 编译安装程序
# （在 Windows 上）
iscc installer/inno-setup/installer.iss

# 执行构建后处理
node installer/build-scripts/post-build.js
```

#### 自动化构建（GitHub Actions）

推送代码到 main 分支或创建版本标签即可触发自动构建：

```bash
# 推送到 main 分支触发构建
git push origin main

# 或创建版本标签触发发布
git tag v1.0.0
git push origin v1.0.0
```

### 3. 构建产物

成功构建后，将在 `dist/` 目录下生成：

- `UniversityMarking-Setup-x86.exe` - 32位安装程序
- `UniversityMarking-Setup-x64.exe` - 64位安装程序
- `RELEASE-NOTES.md` - 发布说明
- `package-info.json` - 构建信息
- `checksums.txt` - 文件校验和

## 安装程序部署

### 1. 单机部署

#### 交互式安装

1. 双击安装程序文件
2. 选择安装语言（中文/英文）
3. 阅读并同意许可协议
4. 选择安装类型（完整/自定义）
5. 选择安装目录
6. 选择附加任务（桌面快捷方式等）
7. 确认安装设置并开始安装
8. 安装完成后选择是否立即启动

#### 静默安装

```cmd
REM 完全静默安装
UniversityMarking-Setup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART

REM 静默安装并生成日志
UniversityMarking-Setup.exe /VERYSILENT /LOG="install.log"

REM 自定义安装目录
UniversityMarking-Setup.exe /VERYSILENT /DIR="C:\CustomPath\UniversityMarking"
```

### 2. 批量部署

#### 使用 GPO（组策略）

1. 将安装程序放置到网络共享文件夹
2. 创建新的 GPO 或编辑现有 GPO
3. 在“计算机配置”-“软件设置”-“软件安装”中添加包
4. 指定安装程序路径和参数
5. 将 GPO 链接到目标 OU

#### 使用 SCCM/MECM

1. 创建应用程序包
2. 配置部署类型和安装程序
3. 设置检测方法和要求
4. 分发给目标设备集合

#### PowerShell 批量脚本

```powershell
# 批量部署脚本示例
$computers = @("PC001", "PC002", "PC003")
$installerPath = "\\server\share\UniversityMarking-Setup.exe"

foreach ($computer in $computers) {
    if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
        Write-Host "Installing on $computer..."
        
        Invoke-Command -ComputerName $computer -ScriptBlock {
            param($installer)
            Start-Process -FilePath $installer -ArgumentList "/VERYSILENT" -Wait
        } -ArgumentList $installerPath
        
        Write-Host "Installation completed on $computer"
    } else {
        Write-Warning "Cannot reach $computer"
    }
}
```

## 配置管理

### 默认配置

安装后，系统使用以下默认配置：

```json
{
  "mainUrl": "http://localhost:8080",
  "LockUrl": "http://localhost:9529/SysLock",
  "UnLockUrl": "http://localhost:9529/LockOut",
  "UnLockPassWord": "admin123"
}
```

### 配置修改

#### 方法 1：使用配置工具

1. 运行“配置工具”（从开始菜单或桌面）
2. 输入考试网址 URL
3. 设置解锁密码
4. 保存配置

#### 方法 2：手动编辑配置文件

编辑 `C:\Program Files\UniversityMarking\app\config\setConfig.json`：

```json
{
  "mainUrl": "https://exam.university.edu",
  "LockUrl": "http://localhost:9529/SysLock",
  "UnLockUrl": "http://localhost:9529/LockOut",
  "UnLockPassWord": "your-secure-password"
}
```

### 批量配置部署

```powershell
# 批量更新配置文件
$configTemplate = @{
    mainUrl = "https://exam.university.edu"
    LockUrl = "http://localhost:9529/SysLock"
    UnLockUrl = "http://localhost:9529/LockOut"
    UnLockPassWord = "secure-password-2024"
}

$computers = @("PC001", "PC002", "PC003")

foreach ($computer in $computers) {
    $configPath = "\\$computer\C$\Program Files\UniversityMarking\app\config\setConfig.json"
    $configTemplate | ConvertTo-Json | Set-Content -Path $configPath
    Write-Host "Configuration updated on $computer"
}
```

## 监控和维护

### 系统监控

#### 服务状态检查

```powershell
# 检查系统服务
Get-Service -Name "UniversityMarkingLockService" | Select-Object Name, Status, StartType

# 检查进程状态
Get-Process | Where-Object { $_.ProcessName -like "*University*" }

# 检查端口占用
netstat -an | findstr :9529
```

#### 日志检查

日志文件位置：
- 应用程序日志：`C:\Program Files\UniversityMarking\logs\`
- 系统事件日志：事件查看器 > 应用程序和服务日志
- 安装日志：`%TEMP%\UniversityMarking-Install.log`

### 常见问题和解决

#### 1. 服务无法启动

**症状：** 系统锁定服务无法启动

**排查步骤：**
```cmd
# 检查服务状态
sc query "UniversityMarkingLockService"

# 查看服务日志
eventvwr.msc

# 手动启动服务
sc start "UniversityMarkingLockService"
```

**解决方案：**
1. 以管理员身份重新注册服务
2. 检查防火墙和杀毒软件设置
3. 确保端口 9529 未被占用

#### 2. 应用程序无法启动

**症状：** 点击桌面快捷方式无响应

**排查步骤：**
1. 检查安装目录是否完整
2. 检查配置文件是否正确
3. 查看应用程序日志

**解决方案：**
1. 重新安装应用程序
2. 更新配置文件
3. 检查网络连接和防火墙设置

#### 3. 键盘锁定失效

**症状：** 系统快捷键仍然可用

**排查步骤：**
1. 检查系统服务状态
2. 检查用户权限
3. 检查其他安全软件冲突

**解决方案：**
1. 以管理员身份重新启动服务
2. 检查并关闭冲突的安全软件
3. 重新安装系统组件

### 更新和升级

#### 小版本更新

1. 下载新版本安装程序
2. 直接运行安装程序（会自动覆盖旧版本）
3. 检查配置文件是否需要更新

#### 主版本升级

1. 先卸载旧版本
2. 备份配置文件
3. 安装新版本
4. 恢复配置文件

## 安全注意事项

### 权限管理
- 始终以最小必要权限运行
- 定期更改解锁密码
- 限制管理员账户的使用

### 网络安全
- 使用 HTTPS 连接考试系统
- 配置防火墙规则限制网络访问
- 定期更新系统和应用程序

### 数据安全
- 定期备份配置文件
- 监控应用程序日志
- 使用安全的密码策略

## 性能优化

### 系统资源优化
- 关闭不必要的后台程序
- 优化内存使用
- 定期清理临时文件和日志

### 网络优化
- 使用局域网内的考试系统
- 配置适当的网络超时设置
- 定期检查网络连接状态

## 技术支持

### 常用工具
- 事件查看器：查看系统日志
- 任务管理器：监控程序和服务
- 服务管理器：管理 Windows 服务
- PowerShell：执行管理脚本

### 联系方式
- 技术文档：检查本文档和 README 文件
- 问题跟踪：提交 GitHub Issues
- 紧急支持：联系项目维护人员

---

**注意：** 本文档随着系统版本更新而更新，请始终参考最新版本的文档。