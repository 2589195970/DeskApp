# UniversityMarking 桌面端应用

[![Build Status](https://github.com/username/UniversityMarking_DeskApp/workflows/Build%20UniversityMarking%20Desktop%20App/badge.svg)](https://github.com/username/UniversityMarking_DeskApp/actions)
[![Release](https://img.shields.io/github/v/release/username/UniversityMarking_DeskApp)](https://github.com/username/UniversityMarking_DeskApp/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> 高性能大学考试监考桌面应用，提供安全的考试环境锁定功能

## 🚀 功能特性

- **🔒 系统锁定服务** - Python后台服务，禁用系统快捷键和任务切换
- **🖥️ 全屏考试界面** - Electron应用，确保考试专注环境  
- **⚙️ 配置管理工具** - 简单易用的配置生成器
- **🛡️ 安全解锁机制** - 密码保护的解锁功能
- **🌏 中文用户名支持** - 完美支持中文Windows用户名
- **⚡ 性能优化** - CPU占用降低60-80%，内存使用优化

## 📋 系统要求

- **操作系统**: Windows 10/11 (推荐)
- **权限**: 管理员权限 (必需)
- **内存**: 2GB+ RAM
- **处理器**: i3或以上 (虚拟化环境: 1核心2GB可运行)

## 🏗️ 项目架构

```
UniversityMarking_DeskApp/
├── Electron_App/          # 主要桌面客户端 (Vue.js + Electron)
├── LockSys_Python/        # 系统锁定服务 (Python + Flask)
├── ChangeConfigUtil/       # 配置工具 (Python + Tkinter)
├── Start_Bat/             # Windows启动脚本
└── .github/workflows/     # GitHub Actions自动构建
```

## 🔧 本地开发

### Electron应用开发
```bash
cd Electron_App
npm install
npm run serve          # 开发服务器
npm run electron:serve  # Electron开发模式
npm run electron:build  # 构建生产版本
```

### Python服务开发
```bash
cd LockSys_Python
pip install -r requirements.txt
python main.py         # 运行锁定服务

# 构建EXE
pip install cx_Freeze
python setup.py build
```

### 配置工具开发
```bash
cd ChangeConfigUtil
python main.py         # 运行配置工具
```

## 📦 自动化构建

项目使用GitHub Actions实现跨平台自动构建：

- **Python服务** → Windows EXE (cx_Freeze)
- **Electron应用** → Windows/macOS/Linux安装包
- **配置工具** → Windows EXE
- **完整发布包** → 自动打包发布

### 触发构建
- Push到 `main`/`master` 分支
- 创建Pull Request
- 创建Release标签

## 🚀 部署安装

### 方式1: 下载Release版本 (推荐)
1. 前往 [Releases页面](https://github.com/username/UniversityMarking_DeskApp/releases)
2. 下载最新版本的完整安装包
3. 解压到目标目录
4. 以**管理员身份**运行 `Start_Bat/start.bat`

### 方式2: 手动构建
1. 克隆仓库: `git clone <repository-url>`
2. 分别构建各个组件
3. 配置启动脚本

## ⚙️ 配置说明

### 配置文件位置
- **Electron配置**: `Electron_App/config/setConfig.json`
- **锁定服务配置**: `LockSys_Python/` (自动生成)

### 主要配置项
```json
{
  "mainUrl": "https://exam.university.edu.cn",
  "LockUrl": "http://localhost:9529/SysLock",
  "UnLockUrl": "http://localhost:9529/LockOut", 
  "UnLockPassWord": "admin123"
}
```

## 🔐 安全特性

- **多层锁定机制**
  - 系统级: 禁用Alt+Tab, Windows键, Ctrl+Shift+Esc等
  - 应用级: 全屏置顶，防止窗口切换
  - 进程级: 持续监控，防止程序退出

- **解锁保护**
  - 密码验证: Ctrl+F10组合键 + 密码确认
  - 管理员权限: 确保锁定功能生效
  - 安全退出: 完整的资源清理机制

## 📊 性能优化

### v2.0 性能提升
- **CPU占用**: 从80%+ 降至 20-30% (改善70%+)
- **内存使用**: 减少30-50%内存占用
- **响应速度**: 智能轮询间隔优化
- **稳定性**: 完善异常处理和资源清理

### 优化技术
- 智能状态检测替代高频轮询
- 日志轮转和级别控制
- 事件驱动架构
- 资源池化管理

## 🐛 故障排除

### 常见问题

**Q: 程序无法启动**
- 确保以管理员权限运行
- 检查端口9529是否被占用
- 查看系统兼容性

**Q: 中文用户名报错**  
- v2.0已完全解决中文路径问题
- 确保使用最新版本

**Q: 性能占用过高**
- 升级到v2.0版本
- 检查虚拟化环境资源分配
- 确认无其他冲突软件

## 🤝 贡献指南

1. Fork项目
2. 创建功能分支: `git checkout -b feature/AmazingFeature`
3. 提交更改: `git commit -m 'Add some AmazingFeature'`
4. 推送分支: `git push origin feature/AmazingFeature`
5. 创建Pull Request

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

- Vue.js 团队 - 优秀的前端框架
- Electron 团队 - 跨平台桌面应用解决方案  
- PyHook3 维护者 - Windows钩子功能
- 所有贡献者和测试用户

---

**⚠️ 重要提醒**: 本软件仅用于合法的考试监考目的，请确保在使用前获得适当的授权许可。