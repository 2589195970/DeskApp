# -*- coding: utf-8 -*-
import ctypes
import sys
from flask import Flask
from gevent import pywsgi
import threading
import os
import log_config
import traceback
import socket

from lock import lockMain
from unlock import unlockMain

# 使用程序目录而非用户目录，避免中文用户名问题
program_dir = os.path.dirname(os.path.abspath(__file__))
flag_file = os.path.join(program_dir, "flag.txt")

# 检查文件是否存在
if not os.path.isfile(flag_file):
    # 文件不存在，创建它
    with open(flag_file, "w+", encoding='utf-8') as file:
        # 可以在这里写入一些内容到文件中
        pass  # 这里仅仅创建文件，不写入内容

    log_config.logging.info(f"文件 '{flag_file}' 不存在，已创建。")


def notify_child_process(key):
    with open(flag_file, "w+", encoding='utf-8') as file:
        file.write(key)

def is_port_in_use(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(("127.0.0.1", port))
            return False
        except OSError:
            return True

# 提升权限
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False


def elevate():
    if not is_admin():
        # 提升权限
        ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, __file__, None, 0)

elevate()
# 要调用的脚本文件
lockPath = "lock.py"
unlockPath = "unlock.py"
child_process = None
loclState = False

app = Flask(__name__)


@app.route("/SysLock")
def SysLock():
    # 锁定系统快捷键
    global child_process, loclState
    if not loclState:
        try:
            notify_child_process("run")
            child_process = threading.Thread(target=lockMain, daemon=True)
            child_process.start()
            loclState = True
            log_config.logging.info("系统锁定已启动")
        except Exception as e:
            log_config.logging.error(f"启动锁定失败: {e}")
            loclState = False
            return "<p>SysLock Failed</p>"
    else:
        log_config.logging.info("当前已锁定，禁止重复锁定监听")
    return "<p>SysLock</p>"


@app.route("/LockOut")
def LockOut():
    global child_process, loclState
    if child_process and loclState:
        try:
            # 发送 SIGTERM 信号给 lock.py 进程
            notify_child_process("exit")
            # 设置超时避免无限等待
            child_process.join(timeout=5.0)
            if child_process.is_alive():
                log_config.logging.warning("子线程未在指定时间内退出")
            child_process = None
            # 注册表清理操作
            unlockMain()
            log_config.logging.info("终止子线程,已退出锁定")
        except Exception as e:
            log_config.logging.error(f"解锁过程异常: {e}")
            child_process = None
    else:
        log_config.logging.info("当前尚未锁定，禁止解锁")
    loclState = False
    return "<p>UnLock Ok</p>"


if __name__ == "__main__":
    try:
        # 检查 9529 端口是否被占用
        port_in_use = is_port_in_use(9529)
        if port_in_use:
            sys.exit()
        else:
            server = pywsgi.WSGIServer(('127.0.0.1', 9529), app)
            server.serve_forever()
    except Exception as e:
        # 这将捕获所有异常，并使用 traceback 打印出错误信息。然后程序将等待用户按下任意键，以便您可以查看错误信息并解决问题。
        traceback.print_exc()
        input("请联系研发人员处理。")