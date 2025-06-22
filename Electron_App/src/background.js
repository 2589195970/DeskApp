'use strict'

import { app, BrowserWindow ,globalShortcut,ipcMain  } from 'electron'
import { createProtocol } from 'vue-cli-plugin-electron-builder/lib'
const path = require('path');
const fs = require('fs');
import axios from 'axios';

let mainWindow = null;
let mainWindowsFocus = true;
let mainWindowsStateInterval = null
let childWindow = null;
let configInfo = {};

const preloadScriptPath = path.join(__dirname,'..','config', 'preload.js');

function createAlertWindow(message) {
  const alertWindow = new BrowserWindow({
    width: 400,
    height: 200,
    frame: false,
    alwaysOnTop: true,
    modal: true,
    show: true,
    webPreferences: {
      nodeIntegration: true,
    },
  });

  alertWindow.loadURL(`data:text/html;charset=utf-8,
    <html>
      <body style="display: flex; align-items: center; justify-content: center; height: 100%; margin: 0;">
        <div style="text-align: center;">
          <h2>${message}</h2>
        </div>
      </body>
    </html>`);
    setTimeout(() => {
      if (alertWindow) {
        alertWindow.hide();
      }
    }, 1000);
}


function fullScreen() {
  if (process.platform === 'darwin') {
    mainWindow.setSimpleFullScreen(true);
  } else {
    mainWindow.setFullScreen(true);
  }
  mainWindow.show();
}

function openInputDialog() {
  mainWindowsFocus = false;
  createChildWindow();
  childWindow.show();
}

function CheckProcess() {
  if (mainWindow) {
    let lastState = {
      isAlwaysOnTop: mainWindow.isAlwaysOnTop(),
      isFocused: mainWindow.isFocused(),
      isMinimized: mainWindow.isMinimized()
    };
    
    // 动态间隔参数
    let currentInterval = 300; // 初始间隔300ms
    let stableCount = 0; // 稳定状态计数
    let maxInterval = 2000; // 最大间隔2秒
    let minInterval = 100; // 最小间隔100ms
    
    const checkWindowState = () => {
      try {
        if (!mainWindow || mainWindow.isDestroyed()) {
          return;
        }
        
        const currentAlwaysOnTop = mainWindow.isAlwaysOnTop();
        const currentFocused = mainWindow.isFocused();
        const currentMinimized = mainWindow.isMinimized();
        
        let hasChanges = false;
        
        // 检测并处理状态变化
        if (!currentAlwaysOnTop && lastState.isAlwaysOnTop !== currentAlwaysOnTop) {
          mainWindow.setAlwaysOnTop(true);
          lastState.isAlwaysOnTop = true;
          hasChanges = true;
        }
        
        if (!currentFocused && mainWindowsFocus && lastState.isFocused !== currentFocused) {
          mainWindow.focus();
          lastState.isFocused = currentFocused;
          hasChanges = true;
        }
        
        if (currentMinimized && lastState.isMinimized !== currentMinimized) {
          mainWindow.show();
          fullScreen();
          lastState.isMinimized = false;
          hasChanges = true;
        } else {
          lastState.isMinimized = currentMinimized;
        }
        
        // 动态调整间隔
        if (hasChanges) {
          // 有变化时，减少间隔以提高响应速度
          stableCount = 0;
          currentInterval = Math.max(minInterval, currentInterval * 0.8);
        } else {
          // 无变化时，逐渐增加间隔以节省CPU
          stableCount++;
          if (stableCount > 5) { // 连续5次无变化后开始增加间隔
            currentInterval = Math.min(maxInterval, currentInterval * 1.2);
          }
        }
        
        // 调度下次检查
        if (mainWindowsStateInterval) {
          mainWindowsStateInterval = setTimeout(checkWindowState, currentInterval);
        }
        
      } catch (error) {
        console.error('窗口状态检查错误:', error);
        // 错误时使用默认间隔重试
        if (mainWindowsStateInterval) {
          mainWindowsStateInterval = setTimeout(checkWindowState, 1000);
        }
      }
    };
    
    // 开始首次检查
    mainWindowsStateInterval = setTimeout(checkWindowState, currentInterval);
    
    // 添加窗口事件监听器以减少轮询依赖
    mainWindow.on('blur', () => {
      if (mainWindowsFocus && !mainWindow.isDestroyed()) {
        setTimeout(() => {
          if (!mainWindow.isDestroyed()) {
            mainWindow.focus();
          }
        }, 50);
      }
    });
    
    mainWindow.on('minimize', () => {
      if (!mainWindow.isDestroyed()) {
        setTimeout(() => {
          if (!mainWindow.isDestroyed()) {
            mainWindow.show();
            fullScreen();
          }
        }, 50);
      }
    });
  }
}

function createChildWindow() {
  if (childWindow != null) {
    return;
  }
  childWindow = new BrowserWindow({ 
    parent: mainWindow,
    width: 600,
    height: 360,
    center: true,
    show: false,
    modal: true,
    "resizable": true,
    titleBarStyle: 'hidden',
    webPreferences: {
      nodeIntegration: true,
      preload: preloadScriptPath, // 加载 preload 脚本
    },
  })

  childWindow.loadURL('app://./index.html');
}

// 网络请求连接池和缓存管理
const requestCache = new Map();
const requestTimeouts = new Map();

async function syncReq(url, options = {}) {
  const {
    timeout = 5000,        // 5秒超时
    maxRetries = 3,        // 最大重试次数
    retryDelay = 1000,     // 重试延迟
    useCache = false,      // 是否使用缓存
    cacheTime = 30000      // 缓存时间30秒
  } = options;
  
  // 检查缓存
  if (useCache && requestCache.has(url)) {
    const cached = requestCache.get(url);
    if (Date.now() - cached.timestamp < cacheTime) {
      console.log(`使用缓存响应: ${url}`);
      return cached.data;
    } else {
      requestCache.delete(url);
    }
  }
  
  let lastError = null;
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(`网络请求尝试 ${attempt}/${maxRetries}: ${url}`);
      
      // 创建带超时的请求
      const cancelToken = axios.CancelToken.source();
      const timeoutId = setTimeout(() => {
        cancelToken.cancel(`请求超时 (${timeout}ms)`);
      }, timeout);
      
      // 保存超时ID以便清理
      requestTimeouts.set(url, timeoutId);
      
      const response = await axios.get(url, {
        cancelToken: cancelToken.token,
        timeout: timeout,
        headers: {
          'User-Agent': 'UniversityMarking-DeskApp/1.0',
          'Connection': 'keep-alive'
        }
      });
      
      // 清理超时
      clearTimeout(timeoutId);
      requestTimeouts.delete(url);
      
      // 缓存成功响应
      if (useCache && response.status === 200) {
        requestCache.set(url, {
          data: response,
          timestamp: Date.now()
        });
      }
      
      console.log(`网络请求成功: ${url}`);
      return response;
      
    } catch (error) {
      lastError = error;
      
      // 清理超时
      if (requestTimeouts.has(url)) {
        clearTimeout(requestTimeouts.get(url));
        requestTimeouts.delete(url);
      }
      
      console.error(`网络请求失败 (尝试 ${attempt}/${maxRetries}):`, error.message);
      
      // 判断是否应该重试
      if (attempt < maxRetries) {
        const shouldRetry = 
          error.code === 'ECONNREFUSED' ||
          error.code === 'ENOTFOUND' ||
          error.code === 'ETIMEDOUT' ||
          (error.response && error.response.status >= 500);
        
        if (shouldRetry) {
          console.log(`等待 ${retryDelay}ms 后重试...`);
          await new Promise(resolve => setTimeout(resolve, retryDelay * attempt));
          continue;
        }
      }
      
      // 不重试或最后一次重试失败
      break;
    }
  }
  
  // 所有重试都失败
  console.error(`网络请求最终失败: ${url}`, lastError);
  throw new Error(`网络请求失败: ${(lastError && lastError.message) || '未知错误'}`);
}

// 清理网络资源的函数
function cleanupNetworkResources() {
  console.log('清理网络资源...');
  
  // 清理缓存
  requestCache.clear();
  
  // 清理未完成的超时
  for (const [url, timeoutId] of requestTimeouts.entries()) {
    clearTimeout(timeoutId);
  }
  requestTimeouts.clear();
  
  console.log('网络资源清理完成');
}

async function createWindow() {
  // Create the browser window.

  mainWindow = new BrowserWindow({
    show: false,
    width: 1024,
    height: 728,
    center: true,
    frame: true,
    "resizable": true,
    fullscreen: true,
    alwaysOnTop: true,
    titleBarStyle: 'hidden',
    webPreferences: {
      nodeIntegration: true,
      preload: preloadScriptPath, // 加载 preload 脚本
    },
  });
  createProtocol('app')

  // 读取 setConfig.json 文件中的 URL
  const setFilePath = path.join(__dirname,'..', 'config', 'setConfig.json');
  // 同步读取文件内容
  const data = fs.readFileSync(setFilePath, 'utf-8');
  // 解析 JSON 数据
  configInfo = JSON.parse(data);
  // 锁定键盘
  await syncReq(configInfo.LockUrl);

  
  mainWindow.loadURL('app://./index.html');
  mainWindow.loadURL(configInfo.mainUrl+'?_r='+Math.random());
  mainWindow.webContents.on('did-finish-load', () => {
    if (!mainWindow) {
      throw new Error('"mainWindow" is not defined');
    }
    if (process.env.START_MINIMIZED) {
      mainWindow.minimize();
    } else {
      mainWindow.show();
    }
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
  // 注册 F11 全屏快捷键并禁用
  globalShortcut.register('F11', () => {
    // 空操作，即不执行任何操作
  });
  
  globalShortcut.register('ctrl+w', () => {
    // 空操作，即不执行任何操作
  });

  // 注册 alt+F1 打开解锁密码窗
  globalShortcut.register('ctrl+F10', () => {
    if (childWindow == null) {
      openInputDialog()
    }else{
      if (childWindow.isVisible()) {
        mainWindowsFocus = true;
        childWindow.hide();
      }else{
        openInputDialog()
      }
    }
  });
  
  // 监听
  ipcMain.on('userCloseUnLockWindow',(even,arg) =>{
    if (childWindow != null) {
      mainWindowsFocus = true;
      childWindow.hide();
    }
  })
  ipcMain.on('userWantCloseTheApp',async (even,args) =>{
    if (args == configInfo.UnLockPassWord) {
      await syncReq(configInfo.UnLockUrl);
      if (process.platform !== 'darwin') {
        app.quit()
      }
    }else{
      createAlertWindow("密码输入错误，请重新输入");
    }
  })

  mainWindow.webContents.on('new-window', (event, url) => {
    event.preventDefault();
    shell.openExternal(url);
  });
  CheckProcess();
  // full Screen！
  fullScreen();
}


// 强化资源清理函数
function cleanupResources() {
  console.log('开始强化资源清理...');
  
  // 清理定时器和间隔器
  if (mainWindowsStateInterval) {
    if (typeof mainWindowsStateInterval === 'number') {
      clearInterval(mainWindowsStateInterval);
    } else {
      clearTimeout(mainWindowsStateInterval);
    }
    mainWindowsStateInterval = null;
    console.log('窗口状态监控已清理');
  }
  
  // 清理网络资源
  try {
    cleanupNetworkResources();
  } catch (error) {
    console.error('清理网络资源时出错:', error);
  }
  
  // 清理全局快捷键
  try {
    globalShortcut.unregisterAll();
    console.log('全局快捷键已清理');
  } catch (error) {
    console.error('清理全局快捷键时出错:', error);
  }
  
  // 清理IPC监听器
  try {
    ipcMain.removeAllListeners('userCloseUnLockWindow');
    ipcMain.removeAllListeners('userWantCloseTheApp');
    console.log('IPC监听器已清理');
  } catch (error) {
    console.error('清理IPC监听器时出错:', error);
  }
  
  // 清理窗口引用
  if (childWindow && !childWindow.isDestroyed()) {
    try {
      childWindow.close();
      childWindow = null;
      console.log('子窗口已清理');
    } catch (error) {
      console.error('清理子窗口时出错:', error);
    }
  }
  
  if (mainWindow && !mainWindow.isDestroyed()) {
    try {
      // 移除所有事件监听器
      mainWindow.removeAllListeners();
      mainWindow = null;
      console.log('主窗口已清理');
    } catch (error) {
      console.error('清理主窗口时出错:', error);
    }
  }
  
  // 强制垃圾回收（如果可用）
  if (global.gc) {
    try {
      global.gc();
      console.log('强制垃圾回收已执行');
    } catch (error) {
      console.error('垃圾回收时出错:', error);
    }
  }
  
  console.log('资源清理完成');
}

// Quit when all windows are closed.
app.on('window-all-closed', () => {
  console.log('所有窗口已关闭，开始清理资源');
  cleanupResources();
  
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('before-quit', (event) => {
  console.log('应用准备退出，执行预清理');
  cleanupResources();
});

app.on('will-quit', (event) => {
  console.log('应用即将退出，执行最终清理');
  cleanupResources();
});

app.on('quit', () => {
  console.log('应用已退出');
});

// 处理未捕获的异常
process.on('uncaughtException', (error) => {
  console.error('未捕获的异常:', error);
  cleanupResources();
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('未处理的Promise拒绝:', reason);
  cleanupResources();
});

app.whenReady().then(createWindow).catch((error) => {
  console.error('应用启动失败:', error);
  cleanupResources();
});

app.on('activate', () => {
  // On macOS it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (mainWindow === null) {
    createWindow();
  }
});