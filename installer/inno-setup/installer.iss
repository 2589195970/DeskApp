; UniversityMarking 系统安装脚本
; 创建时间: 2025-06-20
; 版本: 1.0.0

[Setup]
; 应用程序基本信息
AppName=UniversityMarking考试监考系统
AppVersion=1.0.0
AppPublisher=University Technology Department
AppPublisherURL=https://github.com/
AppSupportURL=https://github.com/
AppUpdatesURL=https://github.com/
DefaultDirName={autopf}\UniversityMarking
DefaultGroupName=UniversityMarking考试监考系统
AllowNoIcons=yes
LicenseFile=resources\license.txt
OutputDir=..\..\dist
OutputBaseFilename=UniversityMarking-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; 架构支持配置
ArchitecturesAllowed=x86 x64
ArchitecturesInstallIn64BitMode=x64

; 权限要求
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

; 界面语言支持
ShowLanguageDialog=yes

[Languages]
Name: "chinesesimp"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1
Name: "configtooldesktop"; Description: "{cm:ConfigToolDesktop}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; Components: configtool
Name: "sendtoicon"; Description: "{cm:SendToMenu}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "associatefiles"; Description: "{cm:FileAssociation}"; GroupDescription: "文件关联"; Flags: unchecked

[Types]
Name: "full"; Description: "{cm:FullInstallation}"
Name: "custom"; Description: "{cm:CustomInstallation}"; Flags: iscustom

[Components]
Name: "main"; Description: "{cm:MainComponent}"; Types: full custom; Flags: fixed
Name: "lockservice"; Description: "{cm:LockServiceComponent}"; Types: full custom
Name: "configtool"; Description: "{cm:ConfigToolComponent}"; Types: full custom

[Files]
; 主程序文件 - Electron App (通用文件)
Source: "..\..\Electron_App\dist\*"; DestDir: "{app}\app"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: main

; 系统锁定服务 - Python (32位版本)
Source: "..\..\LockSys_Python\dist\win32\*"; DestDir: "{app}\service"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: lockservice; Check: not IsWin64

; 系统锁定服务 - Python (64位版本)
Source: "..\..\LockSys_Python\dist\win64\*"; DestDir: "{app}\service"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: lockservice; Check: IsWin64

; 配置工具 (32位版本)
Source: "..\..\ChangeConfigUtil\dist\win32\*"; DestDir: "{app}\config"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: configtool; Check: not IsWin64

; 配置工具 (64位版本)
Source: "..\..\ChangeConfigUtil\dist\win64\*"; DestDir: "{app}\config"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: configtool; Check: IsWin64

; 启动脚本
Source: "..\..\Start_Bat\start.bat"; DestDir: "{app}"; Flags: ignoreversion; Components: main

; 服务管理脚本
Source: "resources\install-service.bat"; DestDir: "{app}"; Flags: ignoreversion; Components: lockservice

; 应用图标 (使用Electron应用的图标)
Source: "..\..\Electron_App\public\favicon.ico"; DestDir: "{app}"; DestName: "icon.ico"; Flags: ignoreversion

; Python运行时 (32位系统)
Source: "..\..\runtime\python-runtime-win32\*"; DestDir: "{app}\runtime"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: not IsWin64; Components: lockservice

; Python运行时 (64位系统)
Source: "..\..\runtime\python-runtime-win64\*"; DestDir: "{app}\runtime"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: IsWin64; Components: lockservice

[Icons]
; 开始菜单项
Name: "{group}\UniversityMarking考试监考系统"; Filename: "{app}\start.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Comment: "启动考试监考系统"
Name: "{group}\配置工具"; Filename: "{app}\config\ChangeConfigUtil.exe"; WorkingDir: "{app}\config"; Components: configtool; Comment: "配置考试系统参数"
Name: "{group}\系统文档"; Filename: "{app}\README.md"; Comment: "查看系统使用说明"
Name: "{group}\{cm:UninstallProgram,UniversityMarking考试监考系统}"; Filename: "{uninstallexe}"; Comment: "卸载考试监考系统"

; 桌面快捷方式 - 主程序
Name: "{autodesktop}\UniversityMarking考试监考系统"; Filename: "{app}\start.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon; Comment: "启动考试监考系统"

; 桌面快捷方式 - 配置工具（可选）
Name: "{autodesktop}\监考系统配置工具"; Filename: "{app}\config\ChangeConfigUtil.exe"; WorkingDir: "{app}\config"; Components: configtool; Tasks: desktopicon; Comment: "配置考试系统参数"; Check: WizardIsTaskSelected('configtooldesktop')

; 快速启动栏
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\UniversityMarking考试监考系统"; Filename: "{app}\start.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Tasks: quicklaunchicon; Comment: "启动考试监考系统"

; 发送到桌面快捷方式（右键菜单）
Name: "{sendto}\UniversityMarking考试监考系统"; Filename: "{app}\start.bat"; WorkingDir: "{app}"; IconFilename: "{app}\icon.ico"; Tasks: sendtoicon

[Run]
; 注册系统锁定服务
Filename: "{sys}\sc.exe"; Parameters: "create ""UniversityMarkingLockService"" binPath= ""{app}\service\main.exe"" start= manual"; StatusMsg: "正在注册系统锁定服务..."; Flags: runhidden waituntilterminated; Components: lockservice; Check: IsAdminLoggedOn

; 设置服务描述
Filename: "{sys}\sc.exe"; Parameters: "description ""UniversityMarkingLockService"" ""UniversityMarking考试系统锁定服务 - 提供系统级别的键盘和鼠标锁定功能"""; Flags: runhidden waituntilterminated; Components: lockservice; Check: IsAdminLoggedOn

; 启动主程序（可选）
Filename: "{app}\start.bat"; Description: "{cm:LaunchProgram,UniversityMarking考试监考系统}"; Flags: nowait postinstall skipifsilent

; 创建服务管理脚本
Filename: "{app}\install-service.bat"; Description: "安装系统服务"; Flags: postinstall skipifsilent runhidden; Components: lockservice; Check: IsAdminLoggedOn

[UninstallRun]
; 停止并删除服务
Filename: "{sys}\sc.exe"; Parameters: "stop ""UniversityMarkingLockService"""; Flags: runhidden; Components: lockservice
Filename: "{sys}\sc.exe"; Parameters: "delete ""UniversityMarkingLockService"""; Flags: runhidden; Components: lockservice

[UninstallDelete]
Type: filesandordirs; Name: "{app}\logs"
Type: filesandordirs; Name: "{app}\temp"

; 自定义消息
[CustomMessages]
; 中文简体消息
chinesesimp.LaunchProgram=启动 %1
chinesesimp.CreateDesktopIcon=创建桌面快捷方式(&D)
chinesesimp.CreateQuickLaunchIcon=创建快速启动栏图标(&Q)
chinesesimp.AdditionalIcons=附加图标:
chinesesimp.UninstallProgram=卸载 %1
chinesesimp.MainComponent=主程序
chinesesimp.LockServiceComponent=系统锁定服务
chinesesimp.ConfigToolComponent=配置工具
chinesesimp.FullInstallation=完整安装
chinesesimp.CustomInstallation=自定义安装
chinesesimp.InstallationProgress=正在安装考试监考系统...
chinesesimp.ServiceInstallation=正在配置系统服务...
chinesesimp.InstallationComplete=安装完成！
chinesesimp.ConfigToolDesktop=为配置工具创建桌面快捷方式
chinesesimp.SendToMenu=添加到"发送到"菜单
chinesesimp.FileAssociation=关联.config配置文件
chinesesimp.RequiresAdmin=此软件需要管理员权限才能正常运行
chinesesimp.ServiceDescription=提供系统级别的键盘和鼠标锁定功能

; 英文消息
english.LaunchProgram=Launch %1
english.CreateDesktopIcon=Create a &desktop icon
english.CreateQuickLaunchIcon=Create a &Quick Launch icon
english.AdditionalIcons=Additional icons:
english.UninstallProgram=Uninstall %1
english.MainComponent=Main Application
english.LockServiceComponent=System Lock Service
english.ConfigToolComponent=Configuration Tool
english.FullInstallation=Full Installation
english.CustomInstallation=Custom Installation
english.InstallationProgress=Installing University Marking System...
english.ServiceInstallation=Configuring system service...
english.InstallationComplete=Installation completed!
english.ConfigToolDesktop=Create desktop shortcut for configuration tool
english.SendToMenu=Add to \"Send To\" menu
english.FileAssociation=Associate .config files
english.RequiresAdmin=This software requires administrator privileges to function properly
english.ServiceDescription=Provides system-level keyboard and mouse locking functionality