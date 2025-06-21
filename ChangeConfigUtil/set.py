from cx_Freeze import setup, Executable

base = None

executables = [
    Executable("main.py", base="Win32GUI", target_name="运行工具.exe", icon="favicon.ico")  # 输出的可执行文件的名称
]

options = {
    "build_exe": {
        "packages": ["tkinter", "json", "pyperclip"],
        "include_files": [],  # 包含其他文件或目录
    },
}

setup(
    name="智多分考试桌面端配置文件生成工具",
    version="1.0",
    description="智多分考试桌面端配置文件生成工具",
    options=options,
    executables=executables
)
