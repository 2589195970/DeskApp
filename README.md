# 智多分机考霸屏桌面端

## 项目简介

智多分机考霸屏桌面端是一个专为大学考试环境设计的安全监考桌面应用程序。该系统通过多层安全架构，创建了一个完全锁定的考试环境，确保考试过程的公平性和安全性。

## 核心功能

### 🔒 系统级安全锁定
- 禁用系统快捷键（Alt+Tab、Windows键、Alt+F4、Ctrl+Shift+Esc等）
- 阻止任务切换和窗口最小化
- 防止访问任务管理器和系统设置

### 🖥️ 全屏监考模式
- 强制全屏显示考试内容
- 窗口置顶且无法移动
- 密码保护的解锁机制（Ctrl+F10）

### ⚙️ 智能配置管理
- 图形化配置工具
- 支持自定义考试网址
- 灵活的密码设置

### 🚀 一键部署
- Windows 安装程序自动配置
- 桌面快捷方式自动创建
- 服务自动注册和启动

## 技术架构

### 主要组件

| 组件 | 技术栈 | 功能描述 |
|------|--------|----------|
| **Electron_App** | Vue.js 2 + Electron | 主界面，负载考试网页并提供安全容器 |
| **LockSys_Python** | Python Flask + PyHook3 | 后台服务，执行系统级键盘鼠标锁定 |
| **ChangeConfigUtil** | Python Tkinter | 配置工具，生成考试参数文件 |
| **Start_Bat** | Windows Batch | 启动脚本，协调各组件运行 |

### 安全模型

```
┌─────────────────────────────────────────┐
│           用户界面层 (Electron)          │
├─────────────────────────────────────────┤
│         应用程序层 (全屏锁定)           │
├─────────────────────────────────────────┤
│        进程监控层 (窗口控制)            │
├─────────────────────────────────────────┤
│       系统服务层 (快捷键拦截)           │
├─────────────────────────────────────────┤
│        操作系统层 (管理员权限)          │
└─────────────────────────────────────────┘
```

## 系统要求

- **操作系统**: Windows 10/11 (推荐)
- **权限**: 管理员权限 (必需)
- **内存**: 2GB+ RAM
- **网络**: 稳定的互联网连接
- **浏览器**: Chromium 内核 (内置)

## 快速开始

### 方式一：使用安装程序 (推荐)

1. 下载 `智多分机考霸屏桌面端-Setup.exe`
2. 右键选择"以管理员身份运行"
3. 按照安装向导完成安装
4. 桌面将出现"智多分机考霸屏桌面端"快捷方式

### 方式二：手动部署

1. 下载完整源码包
2. 解压到目标目录
3. 以管理员身份运行 `Start_Bat/start.bat`
4. 按提示完成配置

## 配置说明

### 考试配置文件 (setConfig.json)

```json
{
  "mainUrl": "https://exam.example.com",
  "LockUrl": "http://localhost:9529/SysLock",
  "UnLockUrl": "http://localhost:9529/LockOut", 
  "UnLockPassWord": "admin123"
}
```

### 配置参数说明

- `mainUrl`: 考试系统网址
- `LockUrl`: 系统锁定API端点
- `UnLockUrl`: 系统解锁API端点  
- `UnLockPassWord`: 管理员解锁密码

## 开发指南

### 环境准备

```bash
# 安装 Node.js 依赖
cd Electron_App
npm install

# 安装 Python 依赖
cd LockSys_Python
pip install -r requirements.txt
```

### 开发命令

```bash
# 启动 Electron 开发服务器
npm run electron:serve

# 构建 Electron 应用
npm run electron:build

# 运行 Python 锁定服务
python LockSys_Python/main.py

# 运行配置工具
python ChangeConfigUtil/main.py
```

### 构建流程

项目使用 GitHub Actions 自动化构建：

1. **构建 Python 组件**: 使用 cx_Freeze 打包为 Windows 可执行文件
2. **构建 Electron 应用**: 使用 electron-builder 生成跨平台应用
3. **生成安装程序**: 使用 Inno Setup 创建 Windows 安装包
4. **自动发布**: 推送到 GitHub Releases

## GitHub Actions 工作流程

我们的 CI/CD 流程包含以下阶段：

### 🔨 构建阶段

| Job | 平台 | 输出 | 描述 |
|-----|------|------|------|
| `build-python-service` | Windows | Python 锁定服务 .exe | 系统级服务打包 |
| `build-config-util` | Windows | 配置工具 .exe | GUI 配置程序 |
| `build-electron-app` | 多平台 | Electron 应用 | 主界面应用程序 |

### 📦 打包阶段

| Job | 功能 | 输出 |
|-----|------|------|
| `create-installer` | 生成 Windows 安装程序 | `智多分机考霸屏桌面端-Setup.exe` |
| `create-release-package` | 创建发布包 | 完整部署包 + 安装程序 |

### 🚀 发布特性

- ✅ **一键安装**: Windows 安装程序自动配置所有组件
- ✅ **桌面快捷方式**: 自动创建桌面启动图标
- ✅ **服务注册**: 自动注册系统服务
- ✅ **权限检查**: 自动验证管理员权限
- ✅ **多语言支持**: 中英双语安装界面

## 安全特性

### 🛡️ 多层防护

1. **系统层防护**: 
   - PyHook3 底层键盘拦截
   - Windows API 调用阻断
   - 进程权限隔离

2. **应用层防护**:
   - Electron 安全沙箱
   - IPC 通信加密
   - 内容安全策略

3. **用户层防护**:
   - 密码保护解锁
   - 操作日志记录
   - 异常行为检测

### 🔐 数据安全

- 所有配置信息本地存储
- 不收集个人敏感信息
- 网络通信仅限考试系统

## 故障排除

### 常见问题

**Q: 无法启动系统锁定服务**
```
A: 请确保以管理员权限运行，并检查防火墙设置
```

**Q: 快捷键仍然有效**
```
A: 检查 Python 服务是否正常运行，端口 9529 是否被占用
```

**Q: 考试页面无法加载**
```
A: 检查网络连接和 setConfig.json 中的 mainUrl 配置
```

### 日志位置

- **Electron 日志**: `%APPDATA%/智多分机考霸屏桌面端/logs/`
- **Python 服务日志**: `LockSys_Python/logs/`
- **系统服务日志**: Windows 事件查看器

## 许可证

本项目采用自定义教育许可证，仅供合法教育机构使用。详见项目根目录的许可证文件。

## 贡献指南

1. Fork 项目仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交变更 (`git commit -m 'Add some AmazingFeature'`)
4. 推送分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 技术支持

- 📧 技术问题: 请提交 [GitHub Issues](https://github.com/2589195970/DeskApp/issues)
- 📖 使用文档: 参考 `installer/docs/` 目录
- 🔧 部署指南: 查看 `installer/docs/DEPLOYMENT_GUIDE.md`

## 版本历史

### v1.0.0 (2025-06-21)
- ✅ 初始版本发布
- ✅ 完整的系统锁定功能
- ✅ Windows 安装程序支持
- ✅ GitHub Actions 自动化构建
- ✅ 桌面快捷方式自动创建

---

**智多分机考霸屏桌面端 - 为公平考试保驾护航** 🎓
