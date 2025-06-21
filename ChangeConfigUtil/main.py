import tkinter as tk
import json
import pyperclip
import os
import shutil


def generate_config():
    address = address_entry.get()

    # 检查是否以"http://"或"https://"开头，如果不是则添加"http://"
    if not address.startswith("http://") and not address.startswith("https://"):
        address = "http://" + address

    config = {
        "mainUrl": address,
        "LockUrl": "http://localhost:9529/SysLock",
        "UnLockUrl": "http://localhost:9529/LockOut",
        "UnLockPassWord": "sdzdf.com"
    }

    with open("setConfig.json", "w") as config_file:
        json.dump(config, config_file)

    # 获取桌面路径
    desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")

    # 将config.json文件复制到桌面
    shutil.copy("setConfig.json", desktop_path)

    result_label.config(text="setConfig.json 文件已生成到桌面，请替换文件到安装目录")


def copy_default_address():
    default_address = r"C:\Users\Public\DeskApp_Sdzdf\resources\config"
    pyperclip.copy(default_address)
    result_label.config(text="已复制默认地址到剪贴板")


# 创建主窗口
root = tk.Tk()
root.title("智多分考试桌面端配置文件生成工具")
# 获取屏幕宽度和高度
screen_width = root.winfo_screenwidth()
screen_height = root.winfo_screenheight()

# 设置窗口大小和位置
window_width = 420
window_height = 290
x = (screen_width - window_width) // 2
y = (screen_height - window_height) // 2
root.geometry(f"{window_width}x{window_height}+{x}+{y}")

# 禁止用户改变窗口大小
root.resizable(False, False)

# 创建标签和输入框
address_label = tk.Label(root, text="请输入考试地址URL:")
address_label.pack(pady=5)

input_font = ("Arial", 14)  # 设置输入框字体
input_width = 32  # 设置输入框宽度
address_entry = tk.Entry(root, font=input_font, width=input_width)
address_entry.pack(pady=5)

# 创建生成按钮
generate_button = tk.Button(root, text="生成替换配置文件", command=generate_config)
generate_button.pack(pady=10)

# 创建复制按钮
copy_button = tk.Button(root, text="复制默认安装地址", command=copy_default_address)
copy_button.pack(pady=5)

# 显示生成结果
result_label = tk.Label(root, text="")
result_label.pack()

# 添加底部提示文本，设置字体为加粗并加大4px
tips_font = ("Arial", 12, "bold")  # 设置字体、大小、加粗
tips_label = tk.Label(root,
                      text="Tips: \n请复制生成后的配置文件到智多分考试桌面端安装地址\n的resources/config文件夹中\n默认地址为：\nC:\\Users\\Public\\DeskApp_Sdzdf\\resources\\config",
                      font=tips_font, anchor="w", justify="left")
tips_label.pack(fill="both", padx=5, pady=5)

# 启动主循环
root.mainloop()
