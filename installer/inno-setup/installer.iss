; 智多分机考霸屏桌面端安装脚本
; 版本: 1.0.0

[Setup]
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
ArchitecturesAllowed=x86 x64
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "main"; Description: "Main Application"; Types: full custom; Flags: fixed
Name: "lockservice"; Description: "System Lock Service"; Types: full custom
Name: "configtool"; Description: "Configuration Tool"; Types: full custom

[Tasks]
Name: "desktopicon"; Description: "Create a desktop icon"; GroupDescription: "Additional icons:"

[Files]
; 主程序文件 - Electron App
Source: "..\..\Electron_App\dist_electron\*"; DestDir: "{app}\app"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: main

; 系统锁定服务 - Python
Source: "..\..\LockSys_Python\build\*"; DestDir: "{app}\service"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: lockservice

; 配置工具
Source: "..\..\ChangeConfigUtil\build\*"; DestDir: "{app}\config"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: configtool

; 启动脚本
Source: "..\..\Start_Bat\start.bat"; DestDir: "{app}"; Flags: ignoreversion; Components: main

; 应用图标
Source: "..\..\Electron_App\public\favicon.ico"; DestDir: "{app}"; DestName: "icon.ico"; Flags: ignoreversion

; 文档
Source: "..\..\README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; 桌面快捷方式
Name: "{autodesktop}\智多分机考霸屏桌面端"; Filename: "{app}\start.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon

; 开始菜单项
Name: "{group}\智多分机考霸屏桌面端"; Filename: "{app}\start.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"
Name: "{group}\卸载智多分机考霸屏桌面端"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\start.bat"; Description: "Launch 智多分机考霸屏桌面端"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\logs"
Type: filesandordirs; Name: "{app}\temp"