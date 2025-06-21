; 智多分机考霸屏桌面端安装脚本
; 版本: 1.0.0

[Setup]
; 应用程序基本信息
AppName=智多分机考霸屏桌面端
AppVersion=1.0.0
AppPublisher=智多分技术团队
DefaultDirName={autopf}\智多分机考霸屏桌面端
DefaultGroupName=智多分机考霸屏桌面端
AllowNoIcons=yes
LicenseFile=resources\license.txt
OutputDir=..\..\dist
OutputBaseFilename=智多分机考霸屏桌面端-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; 架构和权限配置
ArchitecturesAllowed=x86 x64
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop icon"; GroupDescription: "Additional icons:"; Flags: checked

[Components]
Name: "main"; Description: "Main Application"; Types: full custom; Flags: fixed
Name: "lockservice"; Description: "System Lock Service"; Types: full custom
Name: "configtool"; Description: "Configuration Tool"; Types: full custom

[Files]
; 主程序文件 - Electron App
Source: "..\..\Electron_App\dist_electron\*"; DestDir: "{app}\app"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: main

; 系统锁定服务 - Python
Source: "..\..\LockSys_Python\build\*"; DestDir: "{app}\service"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: lockservice

; 配置工具
Source: "..\..\ChangeConfigUtil\build\*"; DestDir: "{app}\config"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: configtool

; 启动脚本
Source: "..\..\Start_Bat\start.bat"; DestDir: "{app}"; Flags: ignoreversion; Components: main

; 服务管理脚本
Source: "resources\install-service.bat"; DestDir: "{app}"; Flags: ignoreversion; Components: lockservice

; 应用图标
Source: "..\..\Electron_App\public\favicon.ico"; DestDir: "{app}"; DestName: "icon.ico"; Flags: ignoreversion

; 文档
Source: "..\..\README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; 开始菜单项
Name: "{group}\智多分机考霸屏桌面端"; Filename: "{app}\start.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Comment: "启动考试监考系统"
Name: "{group}\卸载智多分机考霸屏桌面端"; Filename: "{uninstallexe}"; Comment: "卸载考试监考系统"

; 桌面快捷方式
Name: "{autodesktop}\智多分机考霸屏桌面端"; Filename: "{app}\start.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon; Comment: "启动考试监考系统"

[Run]
; 启动主程序（可选）
Filename: "{app}\start.bat"; Description: "Launch 智多分机考霸屏桌面端"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\logs"
Type: filesandordirs; Name: "{app}\temp"