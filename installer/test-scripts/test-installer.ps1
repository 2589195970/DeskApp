# UniversityMarking 安装程序测试脚本
# PowerShell 测试脚本，用于验证安装程序的功能和正确性

param(
    [Parameter(Mandatory=$false)]
    [string]$InstallerPath = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$SilentTest = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Cleanup = $false
)

# 全局变量
$global:TestResults = @()
$global:TestStartTime = Get-Date
$global:LogFile = "installer-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# 日志函数
function Write-TestLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Write-Host $logEntry
    Add-Content -Path $global:LogFile -Value $logEntry
}

# 测试结果记录
function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Details = ""
    )
    
    $result = @{
        TestName = $TestName
        Success = $Success
        Details = $Details
        Timestamp = Get-Date
    }
    
    $global:TestResults += $result
    
    $status = if ($Success) { "PASS" } else { "FAIL" }
    Write-TestLog "$TestName: $status - $Details" $(if ($Success) { "INFO" } else { "ERROR" })
}

# 检查管理员权限
function Test-AdminPrivileges {
    Write-TestLog "Testing administrator privileges..."
    
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        Add-TestResult "Administrator Privileges" $isAdmin $(if ($isAdmin) { "Running with admin rights" } else { "Not running as administrator" })
        return $isAdmin
    }
    catch {
        Add-TestResult "Administrator Privileges" $false "Error checking privileges: $($_.Exception.Message)"
        return $false
    }
}

# 检查安装程序文件
function Test-InstallerFile {
    param([string]$Path)
    
    Write-TestLog "Testing installer file: $Path"
    
    if (-not (Test-Path $Path)) {
        Add-TestResult "Installer File Exists" $false "File not found: $Path"
        return $false
    }
    
    $fileInfo = Get-Item $Path
    $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
    
    # 检查文件大小是否合理（至少 5MB）
    if ($fileInfo.Length -lt 5MB) {
        Add-TestResult "Installer File Size" $false "File too small: ${fileSizeMB}MB"
        return $false
    }
    
    # 检查文件扩展名
    if ($fileInfo.Extension -ne ".exe") {
        Add-TestResult "Installer File Type" $false "Not an executable file: $($fileInfo.Extension)"
        return $false
    }
    
    Add-TestResult "Installer File Validation" $true "File size: ${fileSizeMB}MB, Type: $($fileInfo.Extension)"
    return $true
}

# 测试静默安装
function Test-SilentInstallation {
    param([string]$InstallerPath)
    
    Write-TestLog "Testing silent installation..."
    
    try {
        $installDir = "$env:ProgramFiles\UniversityMarking"
        $logPath = "$env:TEMP\UniversityMarking-Install.log"
        
        # 清理之前的安装
        if (Test-Path $installDir) {
            Write-TestLog "Removing previous installation..."
            Remove-Item $installDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # 执行静默安装
        $arguments = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /LOG=`"$logPath`""
        $process = Start-Process -FilePath $InstallerPath -ArgumentList $arguments -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Add-TestResult "Silent Installation" $true "Installation completed with exit code 0"
            return $true
        } else {
            Add-TestResult "Silent Installation" $false "Installation failed with exit code $($process.ExitCode)"
            return $false
        }
    }
    catch {
        Add-TestResult "Silent Installation" $false "Error during installation: $($_.Exception.Message)"
        return $false
    }
}

# 测试安装结果
function Test-InstallationResult {
    Write-TestLog "Testing installation result..."
    
    $installDir = "$env:ProgramFiles\UniversityMarking"
    $success = $true
    
    # 检查安装目录
    if (-not (Test-Path $installDir)) {
        Add-TestResult "Installation Directory" $false "Installation directory not found: $installDir"
        $success = $false
    } else {
        Add-TestResult "Installation Directory" $true "Directory exists: $installDir"
    }
    
    # 检查关键文件
    $requiredFiles = @(
        "start.bat",
        "app\*",
        "service\*",
        "config\*"
    )
    
    foreach ($file in $requiredFiles) {
        $fullPath = Join-Path $installDir $file
        if (Test-Path $fullPath) {
            Add-TestResult "Required File: $file" $true "File exists"
        } else {
            Add-TestResult "Required File: $file" $false "File missing"
            $success = $false
        }
    }
    
    # 检查桌面快捷方式
    $desktopShortcut = "$env:PUBLIC\Desktop\UniversityMarking考试监考系统.lnk"
    if (Test-Path $desktopShortcut) {
        Add-TestResult "Desktop Shortcut" $true "Shortcut created"
    } else {
        Add-TestResult "Desktop Shortcut" $false "Shortcut not found"
    }
    
    # 检查开始菜单项
    $startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\UniversityMarking考试监考系统"
    if (Test-Path $startMenuPath) {
        Add-TestResult "Start Menu Items" $true "Start menu folder created"
    } else {
        Add-TestResult "Start Menu Items" $false "Start menu folder not found"
    }
    
    return $success
}

# 测试服务注册
function Test-ServiceRegistration {
    Write-TestLog "Testing service registration..."
    
    try {
        $service = Get-Service -Name "UniversityMarkingLockService" -ErrorAction SilentlyContinue
        
        if ($service) {
            Add-TestResult "Service Registration" $true "Service exists: $($service.Status)"
            return $true
        } else {
            Add-TestResult "Service Registration" $false "Service not found"
            return $false
        }
    }
    catch {
        Add-TestResult "Service Registration" $false "Error checking service: $($_.Exception.Message)"
        return $false
    }
}

# 测试卸载功能
function Test-Uninstallation {
    Write-TestLog "Testing uninstallation..."
    
    try {
        # 查找卸载程序
        $uninstallKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
                       Where-Object { $_.DisplayName -like "*UniversityMarking*" }
        
        if (-not $uninstallKey) {
            Add-TestResult "Uninstall Registry" $false "Uninstall entry not found in registry"
            return $false
        }
        
        $uninstallString = $uninstallKey.UninstallString
        if (-not $uninstallString) {
            Add-TestResult "Uninstall String" $false "Uninstall string not found"
            return $false
        }
        
        # 执行静默卸载
        $arguments = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
        $process = Start-Process -FilePath $uninstallString.Split('"')[1] -ArgumentList $arguments -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Add-TestResult "Uninstallation" $true "Uninstallation completed with exit code 0"
            return $true
        } else {
            Add-TestResult "Uninstallation" $false "Uninstallation failed with exit code $($process.ExitCode)"
            return $false
        }
    }
    catch {
        Add-TestResult "Uninstallation" $false "Error during uninstallation: $($_.Exception.Message)"
        return $false
    }
}

# 生成测试报告
function Generate-TestReport {
    Write-TestLog "Generating test report..."
    
    $totalTests = $global:TestResults.Count
    $passedTests = ($global:TestResults | Where-Object { $_.Success }).Count
    $failedTests = $totalTests - $passedTests
    $testDuration = (Get-Date) - $global:TestStartTime
    
    $reportContent = @"
# UniversityMarking 安装程序测试报告

## 测试概要
- 测试时间: $($global:TestStartTime.ToString('yyyy-MM-dd HH:mm:ss'))
- 测试时长: $($testDuration.ToString('hh\:mm\:ss'))
- 总测试数: $totalTests
- 通过数: $passedTests
- 失败数: $failedTests
- 成功率: $([math]::Round($passedTests / $totalTests * 100, 2))%

## 详细结果

"@
    
    foreach ($result in $global:TestResults) {
        $status = if ($result.Success) { "✅ PASS" } else { "❌ FAIL" }
        $reportContent += "### $($result.TestName) $status`n"
        $reportContent += "- 时间: $($result.Timestamp.ToString('HH:mm:ss'))`n"
        $reportContent += "- 详情: $($result.Details)`n`n"
    }
    
    $reportFile = "installer-test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $reportContent | Out-File -FilePath $reportFile -Encoding UTF8
    
    Write-TestLog "Test report generated: $reportFile"
    return $reportFile
}

# 主测试流程
function Main {
    Write-TestLog "Starting UniversityMarking installer tests..."
    Write-TestLog "PowerShell Version: $($PSVersionTable.PSVersion)"
    Write-TestLog "OS Version: $(Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Caption)"
    
    # 检查管理员权限
    if (-not (Test-AdminPrivileges)) {
        Write-TestLog "Administrator privileges required. Please run as administrator." "ERROR"
        return $false
    }
    
    # 确定安装程序路径
    if ([string]::IsNullOrEmpty($InstallerPath)) {
        $InstallerPath = Get-ChildItem -Path "..\..\dist" -Filter "*.exe" | Select-Object -First 1 -ExpandProperty FullName
        if ([string]::IsNullOrEmpty($InstallerPath)) {
            Write-TestLog "No installer found in dist directory" "ERROR"
            return $false
        }
    }
    
    Write-TestLog "Using installer: $InstallerPath"
    
    # 测试步骤
    $allTestsPassed = $true
    
    # 1. 文件验证
    $allTestsPassed = (Test-InstallerFile $InstallerPath) -and $allTestsPassed
    
    # 2. 静默安装
    if ($SilentTest) {
        $allTestsPassed = (Test-SilentInstallation $InstallerPath) -and $allTestsPassed
        
        # 3. 安装结果验证
        $allTestsPassed = (Test-InstallationResult) -and $allTestsPassed
        
        # 4. 服务注册验证
        $allTestsPassed = (Test-ServiceRegistration) -and $allTestsPassed
        
        # 5. 卸载测试
        if ($Cleanup) {
            $allTestsPassed = (Test-Uninstallation) -and $allTestsPassed
        }
    }
    
    # 生成报告
    $reportFile = Generate-TestReport
    
    # 输出结果
    $totalTests = $global:TestResults.Count
    $passedTests = ($global:TestResults | Where-Object { $_.Success }).Count
    
    Write-TestLog "Test completed. Results: $passedTests/$totalTests passed"
    Write-TestLog "Report saved to: $reportFile"
    
    if ($allTestsPassed) {
        Write-TestLog "All tests PASSED!" "INFO"
        return $true
    } else {
        Write-TestLog "Some tests FAILED!" "ERROR"
        return $false
    }
}

# 执行主程序
try {
    $result = Main
    exit $(if ($result) { 0 } else { 1 })
}
catch {
    Write-TestLog "Unexpected error: $($_.Exception.Message)" "ERROR"
    exit 1
}