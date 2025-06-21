# -*- coding: utf-8 -*-
import ctypes
import sys
import winreg

import log_config

# https://admx.help/ 网站收录了各种有用的东西，注册表信息就是从这里找到的
# 太有用了，一定要谨记
lockValue = 0


# 提升权限
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False


def elevate():
    if not is_admin():
        # 提升权限
        ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, __file__, None, 1)


def regLockTaskMgr():
    # 定义注册表项路径
    global lockValue
    reg_key_path = r"Software\Microsoft\Windows\CurrentVersion\Policies\System"
    try:
        # 尝试打开注册表项，如果不存在，就创建它
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, reg_key_path, 0, winreg.KEY_WRITE)
    except FileNotFoundError:
        # 如果找不到键，就创建它
        key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, reg_key_path)

    try:
        # 创建或修改名为 "DisableTaskMgr" 的 DWORD 键值，将其值设置为 1
        winreg.SetValueEx(key, "DisableTaskMgr", 0, winreg.REG_DWORD, lockValue)
        # 关闭注册表项
        winreg.CloseKey(key)
        log_config.logging.info("已成功解禁 windows资源管理器。")
    except Exception as e:
        log_config.logging.error(f"解禁windows资源管理器。时出现错误:{e}")


def regLockSwitchUser():
    global lockValue
    reg_key_path = r"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    try:
        # 尝试打开注册表项，如果不存在，就创建它
        key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, reg_key_path, 0, winreg.KEY_WRITE)
    except FileNotFoundError:
        # 如果找不到键，就创建它
        key = winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, reg_key_path)

    try:
        # 创建或修改名为 "HideFastUserSwitching" 的 DWORD 键值，将其值设置为 1，这将禁用切换用户功能。
        winreg.SetValueEx(key, "HideFastUserSwitching", 0, winreg.REG_DWORD, lockValue)
        # 关闭注册表项
        winreg.CloseKey(key)
        log_config.logging.info("已成功解禁 切换用户。")
    except Exception as e:
        log_config.logging.error(f"解禁切换用户时出现错误:{e}")


def regLockUserLoginOffAndClose():
    global lockValue
    reg_key_path = r"Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    try:
        # 尝试打开注册表项，如果不存在，就创建它
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, reg_key_path, 0, winreg.KEY_WRITE)
    except FileNotFoundError:
        # 如果找不到键，就创建它
        key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, reg_key_path)

    try:
        winreg.SetValueEx(key, "NoLogoff", 0, winreg.REG_DWORD, lockValue)
        winreg.SetValueEx(key, "NoClose", 0, winreg.REG_DWORD, lockValue)
        # 关闭注册表项
        winreg.CloseKey(key)
        log_config.logging.info("已成功解禁 注销用户。")
    except Exception as e:
        log_config.logging.error(f"解禁注销用户时出现错误:{e}")


def regLockWorkstationAndChangePassword():
    global lockValue
    reg_key_path = r"Software\Microsoft\Windows\CurrentVersion\Policies\System"
    try:
        # 尝试打开注册表项，如果不存在，就创建它
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, reg_key_path, 0, winreg.KEY_WRITE)
    except FileNotFoundError:
        # 如果找不到键，就创建它
        key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, reg_key_path)

    try:
        winreg.SetValueEx(key, "DisableLockWorkstation", 0, winreg.REG_DWORD, lockValue)
        winreg.SetValueEx(key, "DisableChangePassword", 0, winreg.REG_DWORD, lockValue)
        # 关闭注册表项
        winreg.CloseKey(key)
        log_config.logging.info("已成功解禁 屏幕锁定。")
    except Exception as e:
        log_config.logging.error(f"解禁屏幕锁定时出现错误:{e}")


def regLockTaskbar():
    h = ctypes.windll.user32.FindWindowA(b'Shell_TrayWnd', None)
    # hide the taskbar
    ctypes.windll.user32.ShowWindow(h, 9)


def unlockMain():
    # 检查并提升管理员权限
    elevate()
    if not is_admin():
        log_config.logging.error('unLock Auth error')
    else:
        #  提权成功
        regLockTaskMgr()
        regLockSwitchUser()
        regLockUserLoginOffAndClose()
        regLockWorkstationAndChangePassword()
        regLockTaskbar()
        # 通知系统更新策略
        ctypes.windll.user32.SystemParametersInfoW(0x0020, 0, 0, 0)
        log_config.logging.info("unLock Reg Success")
