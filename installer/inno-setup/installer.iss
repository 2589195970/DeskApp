; 智多分机考霸屏桌面端安装脚本
; 版本: 1.0.0 - 支持 Win7 SP1 和多架构 (x86/x64)

#define MyAppName "智多分机考霸屏桌面端"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "智多分技术团队"
#define MyAppURL "https://github.com/your-repo/UniversityMarking"

; 专注32位架构
#ifdef ARCHITECTURE
  #define TargetArch ARCHITECTURE
#else
  #define TargetArch "x86"
#endif

#if TargetArch == "x86"
  #define ArchSuffix "ia32"
  #define ArchDisplay "32位"
  #define PythonArchSuffix "32"
#else
  #define ArchSuffix "x64"
  #define ArchDisplay "64位"
  #define PythonArchSuffix "64"
#endif

[Setup]
AppId={{8B3F5C2A-1E4D-4A9B-8F7E-2C3D4E5F6A7B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=resources\license.txt
OutputDir=..\..\dist
OutputBaseFilename=UniversityMarking-Setup-{#TargetArch}
SetupIconFile=resources\icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; Win7 SP1 兼容性设置
MinVersion=6.1.7601
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

; 架构限制
#if TargetArch == "x86"
ArchitecturesAllowed=x86 x64
ArchitecturesInstallIn64BitMode=
#else
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
#endif

[Languages]
Name: "chinesesimp"; MessagesFile: "compiler:Languages\ChineseSimp.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "完整安装"; Languages: chinesesimp
Name: "full"; Description: "Full installation"; Languages: english
Name: "custom"; Description: "自定义安装"; Flags: iscustom; Languages: chinesesimp
Name: "custom"; Description: "Custom installation"; Flags: iscustom; Languages: english

[Components]
Name: "main"; Description: "主程序 ({#ArchDisplay})"; Types: full custom; Flags: fixed; Languages: chinesesimp
Name: "main"; Description: "Main Application ({#ArchDisplay})"; Types: full custom; Flags: fixed; Languages: english
Name: "lockservice"; Description: "系统锁定服务"; Types: full custom; Languages: chinesesimp
Name: "lockservice"; Description: "System Lock Service"; Types: full custom; Languages: english
Name: "configtool"; Description: "配置工具"; Types: full custom; Languages: chinesesimp
Name: "configtool"; Description: "Configuration Tool"; Types: full custom; Languages: english

[Tasks]
Name: "desktopicon"; Description: "创建桌面图标"; GroupDescription: "附加图标:"; Languages: chinesesimp
Name: "desktopicon"; Description: "Create a desktop icon"; GroupDescription: "Additional icons:"; Languages: english

[Files]
; 主程序文件 - Electron App (架构相关)
Source: "..\..\Electron_App\dist_electron\win-{#ArchSuffix}-unpacked\*"; DestDir: "{app}\app"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: main

; 系统锁定服务 - Python (架构相关)
Source: "..\..\LockSys_Python\dist\win{#PythonArchSuffix}\*"; DestDir: "{app}\service"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: lockservice

; 配置工具 - Python (架构相关)
Source: "..\..\ChangeConfigUtil\dist\win{#PythonArchSuffix}\*"; DestDir: "{app}\config"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: configtool

; 启动脚本
Source: "..\..\Start_Bat\start.bat"; DestDir: "{app}"; Flags: ignoreversion; Components: main

; 应用图标
Source: "resources\icon.ico"; DestDir: "{app}"; Flags: ignoreversion

; 配置模板
Source: "..\..\Electron_App\config\setConfig.json"; DestDir: "{app}\config"; Flags: ignoreversion; Components: main

; 文档
Source: "..\..\README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme
Source: "..\..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion; DestName: "LICENSE.txt"

[Dirs]
Name: "{app}\logs"; Permissions: everyone-full
Name: "{app}\temp"; Permissions: everyone-full

[Icons]
; 桌面快捷方式
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\start.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon; Comment: "启动智多分机考霸屏桌面端"

; 开始菜单项
Name: "{group}\{#MyAppName}"; Filename: "{app}\start.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Comment: "启动智多分机考霸屏桌面端"
Name: "{group}\配置工具"; Filename: "{app}\config\main.exe"; WorkingDir: "{app}\config"; IconFilename: "{app}\icon.ico"; Components: configtool
Name: "{group}\使用说明"; Filename: "{app}\README.md"; WorkingDir: "{app}"
Name: "{group}\卸载 {#MyAppName}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\start.bat"; Description: "立即启动 {#MyAppName}"; Flags: nowait postinstall skipifsilent; Languages: chinesesimp
Filename: "{app}\start.bat"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent; Languages: english

[UninstallDelete]
Type: filesandordirs; Name: "{app}\logs"
Type: filesandordirs; Name: "{app}\temp"
Type: filesandordirs; Name: "{app}\config\setConfig.json"

[Code]
function IsWin7SP1OrLater: Boolean;
var
  Version: TWindowsVersion;
begin
  GetWindowsVersionEx(Version);
  Result := (Version.Major > 6) or 
           ((Version.Major = 6) and (Version.Minor > 1)) or
           ((Version.Major = 6) and (Version.Minor = 1) and (Version.ServicePackMajor >= 1));
end;

function InitializeSetup: Boolean;
begin
  if not IsWin7SP1OrLater then
  begin
    MsgBox('此程序需要 Windows 7 SP1 或更高版本。' + #13#10 + 
           'This program requires Windows 7 SP1 or later.', mbCriticalError, MB_OK);
    Result := False;
  end
  else
    Result := True;
end;