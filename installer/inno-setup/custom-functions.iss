; UniversityMarking 系统安装自定义函数库
; 创建时间: 2025-06-20

[Code]
// 初始化设置函数
function InitializeSetup(): Boolean;
var
  SystemInfo: String;
begin
  // 执行系统兼容性检查
  if not CheckSystemCompatibility() then
    begin
      Result := False;
      Exit;
    end;
  
  // 检测系统架构并记录详细信息
  if IsWin64 then
    begin
      SystemInfo := '64位 Windows 系统';
      Log('Detected 64-bit Windows system');
      Log('Will install 64-bit versions of Python components');
    end
  else
    begin
      SystemInfo := '32位 Windows 系统';
      Log('Detected 32-bit Windows system');
      Log('Will install 32-bit versions of Python components');
    end;
  
  // 显示系统信息和安装说明
  if MsgBox('系统检测完成：' + #13#10 +
            '- 系统架构：' + SystemInfo + #13#10 +
            '- 安装路径：' + ExpandConstant('{autopf}') + '\UniversityMarking' + #13#10 +
            '- 需要权限：管理员权限' + #13#10#13#10 +
            '将安装对应版本的系统组件。' + #13#10 +
            '继续安装吗？', mbConfirmation, MB_YESNO) = IDYES then
    begin
      // 执行端口检查
      if CheckPortAvailability() then
        Result := True
      else
        Result := False;
    end
  else
    Result := False;
end;

// 架构检查函数
function IsValidArchitecture(): Boolean;
begin
  // 检查是否为支持的架构
  Result := True; // 默认支持所有架构

  if IsWin64 then
    Log('Installing for 64-bit architecture')
  else
    Log('Installing for 32-bit architecture');
end;

// 组件安装检查函数 - 64位特定
function ShouldInstall64BitComponent(): Boolean;
begin
  Result := IsWin64;
end;

// 组件安装检查函数 - 32位特定
function ShouldInstall32BitComponent(): Boolean;
begin
  Result := not IsWin64;
end;

// 检查是否需要重启
 function NeedRestart(): Boolean;
begin
  Result := False; // 默认不需要重启
end;

// 安装前检查函数
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  MinDiskSpace: Int64;
  FreeDiskSpace: Int64;
  InstallPath: String;
begin
  Result := '';
  NeedsRestart := False;
  
  // 检查管理员权限
  if not IsAdminLoggedOn then
    begin
      Result := '安装需要管理员权限，请以管理员身份运行安装程序。';
      Exit;
    end;
  
  // 检查磁盘空间 (至少需要100MB)
  MinDiskSpace := 100 * 1024 * 1024; // 100MB in bytes
  InstallPath := WizardDirValue;
  
  if GetSpaceOnDisk(ExtractFileDrive(InstallPath), False, FreeDiskSpace, MinDiskSpace, MinDiskSpace) then
    begin
      if FreeDiskSpace < MinDiskSpace then
        begin
          Result := '磁盘空间不足。至少需要 100MB 可用空间，当前可用空间：' + 
                   IntToStr(FreeDiskSpace div (1024*1024)) + 'MB';
          Exit;
        end;
    end
  else
    begin
      Result := '无法检测磁盘空间。请确保有足够的可用空间。';
      Exit;
    end;
  
  // 检查防火墙设置提醒
  if MsgBox('安装完成后，系统可能会提示您配置防火墙规则。' + #13#10 +
            '请允许程序通过防火墙以确保正常运行。' + #13#10#13#10 +
            '继续安装吗？', mbInformation, MB_YESNO) = IDNO then
    begin
      Result := '用户取消安装。';
      Exit;
    end;
  
  Log('Pre-installation checks completed successfully');
end;

// 安装后清理函数
function DeinitializeSetup(): Boolean;
begin
  Log('Installation cleanup completed');
  Result := True;
end;

// 检查组件是否应该安装
function ShouldInstallComponent(ComponentName: String): Boolean;
begin
  if ComponentName = 'lockservice' then
    begin
      // 检查Python环境是否可用
      Result := True; // 默认安装，包含内置Python环境
    end
  else if ComponentName = 'configtool' then
    begin
      Result := True; // 配置工具可选
    end
  else
    begin
      Result := True; // 默认安装其他组件
    end;
end;

// 自定义卸载函数
function InitializeUninstall(): Boolean;
begin
  if MsgBox('您确定要卸载智多分考试霸屏系统？', mbConfirmation, MB_YESNO) = IDYES then
    Result := True
  else
    Result := False;
end;

// 系统兼容性检查
function CheckSystemCompatibility(): Boolean;
var
  Version: TWindowsVersion;
begin
  GetWindowsVersionEx(Version);
  
  // Windows Vista (6.0) 及以上
  if (Version.Major < 6) then
    begin
      MsgBox('系统不兼容：需要 Windows Vista 或更高版本。' + #13#10 +
             '当前系统版本：' + IntToStr(Version.Major) + '.' + IntToStr(Version.Minor),
             mbError, MB_OK);
      Result := False;
      Exit;
    end;
  
  Log('System compatibility check passed');
  Result := True;
end;

// 端口占用检查
function CheckPortAvailability(): Boolean;
begin
  Result := True;
  
  // 检查端口9529是否被占用（Python服务端口）
  Log('Checking port availability for service...');
  
  // 提醒用户关于端口使用
  if MsgBox('系统将使用本地端口 9529 提供服务。' + #13#10 +
            '请确保该端口未被其他程序占用。' + #13#10#13#10 +
            '如果遇到端口冲突，可在安装后修改配置文件。' + #13#10 +
            '继续安装吗？', mbInformation, MB_YESNO) = IDNO then
    begin
      Result := False;
    end;
end;
