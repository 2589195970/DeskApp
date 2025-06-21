# UniversityMarking 安装程序测试脚本

本目录包含用于测试 UniversityMarking 安装程序的脚本和工具。

## 文件说明

### test-installer.ps1
PowerShell 测试脚本，提供全面的安装程序测试功能。

**功能特性：**
- 管理员权限检查
- 安装程序文件验证
- 静默安装测试
- 安装结果验证
- 服务注册检查
- 卸载功能测试
- 详细测试报告生成

**使用方法：**
```powershell
# 基本测试（仅文件验证）
.\test-installer.ps1

# 全面静默测试
.\test-installer.ps1 -SilentTest

# 包含卸载测试
.\test-installer.ps1 -SilentTest -Cleanup

# 指定安装程序路径
.\test-installer.ps1 -InstallerPath "C:\path\to\installer.exe" -SilentTest
```

### test-installer.bat
Windows Batch 测试脚本，提供基本的安装程序测试功能。

**功能特性：**
- 管理员权限检查
- 安装程序文件查找
- 文件信息验证
- 系统兼容性检查
- 安装参数测试
- 简单测试报告

**使用方法：**
```batch
REM 以管理员身份运行
test-installer.bat
```

## 测试环境要求

### 基本要求
- Windows Vista 或更高版本
- 管理员权限
- PowerShell 5.0+ （针对 PowerShell 脚本）

### 推荐配置
- Windows 10/11
- 4GB+ 内存
- 1GB+ 可用磁盘空间
- 稳定的网络连接

## 测试场景

### 1. CI/CD 环境测试
在 GitHub Actions 或其他 CI/CD 系统中使用：

```yaml
- name: Test Installer
  run: |
    installer\test-scripts\test-installer.bat
```

### 2. 手动测试
在本地开发环境中执行详细测试：

```powershell
# 以管理员身份启动 PowerShell
Start-Process PowerShell -Verb RunAs

# 执行测试
cd installer\test-scripts
.\test-installer.ps1 -SilentTest
```

### 3. 生产环境验证
在目标部署环境中验证安装程序：

```powershell
# 仅文件验证，不实际安装
.\test-installer.ps1

# 实际安装测试（谨慎使用）
.\test-installer.ps1 -SilentTest -Cleanup
```

## 测试结果输出

### 日志文件
- `installer-test-YYYYMMDD-HHMMSS.log` - 详细测试日志
- `installer-test-report-YYYYMMDD-HHMMSS.md` - Markdown 格式测试报告
- `installer-test-report-YYYYMMDD-HHMMSS.txt` - 简单文本报告

### 退出代码
- `0` - 所有测试通过
- `1` - 有测试失败

## 常见问题解决

### 1. 权限问题
**问题：** “需要管理员权限”
**解决：** 右键 PowerShell 或命令提示符，选择“以管理员身份运行”

### 2. 执行策略问题
**问题：** PowerShell 执行策略限制
**解决：**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. 安装程序未找到
**问题：** “在 dist 目录中未找到安装程序”
**解决：**
1. 确保已执行构建流程
2. 检查 `dist` 目录是否存在
3. 使用 `-InstallerPath` 参数指定安装程序路径

### 4. 服务注册失败
**问题：** Windows 服务注册失败
**解决：**
1. 确保以管理员身份运行
2. 检查防火墙和杀毒软件设置
3. 手动执行服务注册命令

## 扩展和定制

如需添加新的测试项目或修改测试逻辑，请参考现有脚本的结构和注释。

主要扩展点：
- 添加新的测试函数
- 修改测试参数和配置
- 自定义报告格式
- 集成其他测试工具

## 联系和支持

如遇到问题或需要技术支持，请：
1. 检查本文档的常见问题解决部分
2. 查看测试日志文件获取详细信息
3. 在项目 GitHub 仓库中提交 Issue