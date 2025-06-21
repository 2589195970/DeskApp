# -*- coding: utf-8 -*-
import ctypes
import os
import sys
import pythoncom
import winreg
from PyHook3 import HookConstants, HookManager, GetKeyState
# import requests
import log_config

# https://admx.help/ 网站收录了各种有用的东西，注册表信息就是从这里找到的
# 太有用了，一定要谨记
lockValue = 1
# 创建一个用于通信的标志文件，使用程序目录避免中文用户名问题
program_dir = os.path.dirname(os.path.abspath(__file__))
flag_file = os.path.join(program_dir, "flag.txt")

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

# 键盘事件处理函数
def OnKeyboardEvent(event):
    # 移除详细按键日志，只记录被阻止的关键操作
    blocked = False
    # 屏蔽组合ALT+TAB
    if GetKeyState(HookConstants.VKeyToID('VK_MENU')) and event.KeyID == HookConstants.VKeyToID(
            'VK_TAB'):  # type: ignore
        blocked = True
        log_config.logging.warning("阻止用户切换窗口(Alt+Tab)")
        return False
    # 屏蔽系统Win
    if event.KeyID == HookConstants.VKeyToID("VK_LWIN") or event.KeyID == HookConstants.VKeyToID(
            "VK_RWIN"):  # type: ignore
        blocked = True
        log_config.logging.warning("阻止用户按下Windows键")
        return False
    # 屏蔽Alt+F4
    if GetKeyState(HookConstants.VKeyToID('VK_MENU')) and event.KeyID == HookConstants.VKeyToID(
            'VK_F4'):  # type: ignore
        blocked = True
        log_config.logging.warning("阻止用户关闭程序(Alt+F4)")
        return False
    # 屏蔽Ctrl+Shift+ESC
    if GetKeyState(HookConstants.VKeyToID('VK_CONTROL')) and GetKeyState(
            HookConstants.VKeyToID('VK_SHIFT')) and event.KeyID == HookConstants.VKeyToID('VK_ESCAPE'):  # type: ignore
        blocked = True
        log_config.logging.warning("阻止用户打开任务管理器(Ctrl+Shift+Esc)")
        return False
    # 屏蔽 DEL
    if event.KeyID == HookConstants.VKeyToID('VK_DELETE'):  # type: ignore
        blocked = True
        return False
    # 屏蔽Ctrl+V
    if GetKeyState(HookConstants.VKeyToID('VK_CONTROL')) and event.KeyID == 0x56:  # type: ignore
        blocked = True
        return False
    # 屏蔽Shift+insert
    if GetKeyState(HookConstants.VKeyToID('VK_SHIFT')) and event.KeyID == HookConstants.VKeyToID(
            'VK_INSERT'):  # type: ignore
        blocked = True
        return False
    # 屏蔽 Ctrl+ALT+DELETE 并不会有效果，因为Ctrl+ALT+DELETE等级太高了 if GetKeyState(HookConstants.VKeyToID('VK_MENU')) and
    # GetKeyState(HookConstants.VKeyToID('VK_CONTROL')) and event.KeyID == HookConstants.VKeyToID('VK_DELETE'):
    # return False 返回True则不会屏蔽对应键

    # 监听一个组合键位，来执行退出。  有点进程上的问题
    # if GetKeyState(HookConstants.VKeyToID('VK_MENU')) and GetKeyState(HookConstants.VKeyToID('VK_SHIFT')) and \
    #         GetKeyState(HookConstants.VKeyToID('VK_CONTROL')) and event.KeyID == 0x51:  # type: ignore
    #     log_config.logging.error("用户通过内置退出锁定快捷键 退出锁定 ALT+CTRL+SHIFT+Q")
    #     requests.get('http://127.0.0.1:9529/LockOut')
    #     return False

    return True


def lock():
    hm = None
    try:
        # 创建hook manager对象
        hm = HookManager()
        # 将OnKeyboardEvent函数绑定到KeyDown事件上
        hm.KeyDown = OnKeyboardEvent
        # 设置键盘钩子
        hm.HookKeyboard()
        log_config.logging.info(f"监听键盘组合按键---启动：{not should_exit()}")
        
        # 智能轮询参数
        idle_count = 0
        max_idle_count = 10
        base_sleep_time = 0.01  # 10ms基础休眠
        max_sleep_time = 0.1    # 100ms最大休眠
        
        while not should_exit():
            try:
                # 处理消息并检查是否有消息处理
                message_count = pythoncom.PumpWaitingMessages()
                
                # 智能休眠机制：没有消息时逐渐增加休眠时间
                if message_count == 0:
                    idle_count = min(idle_count + 1, max_idle_count)
                    sleep_time = min(base_sleep_time * (idle_count + 1), max_sleep_time)
                else:
                    idle_count = 0
                    sleep_time = base_sleep_time
                
                # 避免CPU空转
                import time
                time.sleep(sleep_time)
                
            except Exception as e:
                log_config.logging.error(f"消息循环异常: {e}")
                break
                
    except Exception as e:
        log_config.logging.error(f"键盘钩子创建失败: {e}")
    finally:
        # 强化资源清理机制
        log_config.logging.info("监听被终止，进行强化清理操作")
        
        # 多重钩子清理策略
        if hm:
            try:
                # 第一步：标准钩子释放
                if hasattr(hm, 'UnhookKeyboard'):
                    hm.UnhookKeyboard()
                    log_config.logging.info("键盘钩子已释放")
                
                # 第二步：强制清理钩子资源
                if hasattr(hm, '_keyboard_hook_id') and hm._keyboard_hook_id:
                    ctypes.windll.user32.UnhookWindowsHookExW(hm._keyboard_hook_id)
                    log_config.logging.info("强制释放底层钩子资源")
                    
                # 第三步：对象清理
                del hm
                hm = None
                
            except Exception as e:
                log_config.logging.error(f"钩子清理异常: {e}")
                # 紧急清理：尝试释放所有可能的钩子
                try:
                    import gc
                    gc.collect()  # 强制垃圾回收
                    log_config.logging.info("执行紧急垃圾回收")
                except:
                    pass
        
        # 清理系统消息队列
        try:
            # 处理剩余消息
            for _ in range(10):  # 最多处理10次
                if pythoncom.PumpWaitingMessages() == 0:
                    break
            
            # 发送退出消息
            ctypes.windll.user32.PostQuitMessage(0)
            log_config.logging.info("系统消息队列已清理")
            
        except Exception as e:
            log_config.logging.error(f"消息队列清理异常: {e}")
        
        # 清理缓存
        try:
            global _file_cache
            _file_cache.clear()
            _file_cache.update({
                'last_check_time': 0,
                'last_mtime': 0,
                'last_result': False,
                'check_interval': 0.5
            })
            log_config.logging.info("文件缓存已重置")
        except Exception as e:
            log_config.logging.error(f"缓存清理异常: {e}")


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
        log_config.logging.info("已成功禁用 windows资源管理器。")
    except Exception as e:
        log_config.logging.error(f'禁用 windows资源管理器。时出现错误：{e}')


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
        log_config.logging.info("已成功禁用 切换用户。")
    except Exception as e:
        log_config.logging.error(f"禁用 切换用户时出现错误:{e}")


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
        log_config.logging.info("已成功禁用 注销用户。")
    except Exception as e:
        log_config.logging.error(f"禁用 注销用户时出现错误:{e}")


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
        log_config.logging.info("已成功禁用 屏幕锁定。")
    except Exception as e:
        log_config.logging.error(f"禁用 屏幕锁定时出现错误:{e}")


def regLockTaskbar():
    h = ctypes.windll.user32.FindWindowA(b'Shell_TrayWnd', None)
    # hide the taskbar
    ctypes.windll.user32.ShowWindow(h, 0)

# 文件状态缓存
_file_cache = {
    'last_check_time': 0,
    'last_mtime': 0,
    'last_result': False,
    'check_interval': 0.5  # 500ms缓存间隔
}

# 子进程中检查标志文件来确定是否退出（带缓存优化）
def should_exit():
    import time
    
    current_time = time.time()
    
    # 如果在缓存间隔内，直接返回上次结果
    if current_time - _file_cache['last_check_time'] < _file_cache['check_interval']:
        return _file_cache['last_result']
    
    try:
        if os.path.exists(flag_file):
            # 检查文件修改时间
            current_mtime = os.path.getmtime(flag_file)
            
            # 如果文件未修改，使用缓存结果
            if current_mtime == _file_cache['last_mtime'] and _file_cache['last_check_time'] > 0:
                _file_cache['last_check_time'] = current_time
                return _file_cache['last_result']
            
            # 文件有修改，重新读取
            with open(flag_file, "r", encoding='utf-8') as file:
                content = file.read().strip()
                result = content == "exit"
                
                # 更新缓存
                _file_cache.update({
                    'last_check_time': current_time,
                    'last_mtime': current_mtime,
                    'last_result': result
                })
                
                return result
        else:
            # 文件不存在
            _file_cache.update({
                'last_check_time': current_time,
                'last_mtime': 0,
                'last_result': False
            })
            return False
            
    except Exception as e:
        log_config.logging.error(f"检查退出标志文件时出错: {e}")
        return False


def lockMain():
    # 检查并提升管理员权限
    elevate()
    if not is_admin():
        log_config.logging.error('Lock Auth error')
    else:
        #  提权成功
        regLockTaskMgr()
        regLockSwitchUser()
        regLockUserLoginOffAndClose()
        regLockWorkstationAndChangePassword()
        regLockTaskbar()
        # 通知系统更新策略
        ctypes.windll.user32.SystemParametersInfoW(0x0020, 0, 0, 0)
        lock()
