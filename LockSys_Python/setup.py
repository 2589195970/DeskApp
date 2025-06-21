# -*- coding: utf-8 -*-
import sys
import os
from cx_Freeze import setup, Executable

# 确定基础配置
base = None
if sys.platform == "win32":
    base = "Win32GUI"  # Windows GUI程序，不显示控制台

# 可执行文件配置
executables = [
    Executable(
        "main.py", 
        base=base, 
        target_name="UniversityMarking_LockService.exe",
        icon=None  # 可以添加图标路径
    )
]

# 构建选项
build_options = {
    "packages": [
        "flask", 
        "gevent", 
        "threading", 
        "logging", 
        "logging.handlers",  # 新增：日志轮转支持
        "PyHook3", 
        "portalocker",
        "ctypes",
        "winreg",
        "pythoncom",
        "os",
        "sys",
        "socket",
        "traceback"
    ],
    "excludes": [
        "unittest",
        "email", 
        "html",
        "urllib",
        "xml",
        "test"
    ],
    "include_files": [
        # 包含配置文件和其他资源
    ],
    "zip_include_packages": ["*"],  # 压缩包减小体积
    "optimize": 2,  # 最高级别优化
    "build_exe": "build/UniversityMarking_LockService"
}

setup(
    name="UniversityMarking_LockService",
    version="2.0.0",
    description="University Examination Lock Service - Enhanced Performance Edition",
    author="UniversityMarking Team",
    options={"build_exe": build_options},
    executables=executables
)
