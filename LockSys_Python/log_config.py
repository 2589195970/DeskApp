# -*- coding: utf-8 -*-
import logging
import logging.handlers
import os
import threading
import queue
import time
import atexit

# 获取程序目录，确保与中文用户名兼容
program_dir = os.path.dirname(os.path.abspath(__file__))
log_file_path = os.path.join(program_dir, 'lockInfo.log')

# 异步日志队列和控制变量
log_queue = queue.Queue(maxsize=1000)  # 限制队列大小防止内存溢出
log_worker_running = True
log_worker_thread = None

# 创建日志记录器
logger = logging.getLogger('UniversityMarking')
logger.setLevel(logging.ERROR)  # 进一步提高日志级别，只记录错误

# 创建轮转文件处理器，限制日志文件大小和数量
file_handler = logging.handlers.RotatingFileHandler(
    log_file_path, 
    maxBytes=512*1024,   # 减少到512KB
    backupCount=2,       # 减少备份文件数量
    encoding='utf-8'     # 确保中文字符正确处理
)

# 设置日志格式（简化格式以减少I/O）
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s', 
                            datefmt='%H:%M:%S')  # 简化时间格式
file_handler.setFormatter(formatter)

class AsyncLogHandler(logging.Handler):
    """异步日志处理器"""
    
    def emit(self, record):
        try:
            # 非阻塞方式放入队列
            log_queue.put_nowait(record)
        except queue.Full:
            # 队列满时丢弃最早的记录
            try:
                log_queue.get_nowait()
                log_queue.put_nowait(record)
            except:
                pass  # 静默处理队列异常

def log_worker():
    """异步日志写入工作线程"""
    batch_records = []
    last_flush_time = time.time()
    flush_interval = 5.0  # 5秒批量写入一次
    
    while log_worker_running or not log_queue.empty():
        try:
            # 批量处理日志记录
            try:
                record = log_queue.get(timeout=1.0)
                batch_records.append(record)
                
                # 累积批量记录或超时批量写入
                current_time = time.time()
                if (len(batch_records) >= 10 or 
                    current_time - last_flush_time >= flush_interval):
                    
                    # 批量写入
                    for batch_record in batch_records:
                        file_handler.emit(batch_record)
                    
                    # 强制刷新到磁盘
                    if hasattr(file_handler, 'flush'):
                        file_handler.flush()
                    
                    batch_records.clear()
                    last_flush_time = current_time
                    
            except queue.Empty:
                # 超时时检查是否有待写入的记录
                if batch_records:
                    for batch_record in batch_records:
                        file_handler.emit(batch_record)
                    if hasattr(file_handler, 'flush'):
                        file_handler.flush()
                    batch_records.clear()
                    last_flush_time = time.time()
                continue
                
        except Exception as e:
            # 日志工作线程异常处理
            try:
                # 尝试直接写入文件处理器
                error_record = logging.LogRecord(
                    name='AsyncLogHandler',
                    level=logging.ERROR,
                    pathname='',
                    lineno=0,
                    msg=f'日志工作线程异常: {e}',
                    args=(),
                    exc_info=None
                )
                file_handler.emit(error_record)
            except:
                pass  # 最后的异常处理也失败时静默处理

def start_async_logging():
    """启动异步日志系统"""
    global log_worker_thread, log_worker_running
    
    if log_worker_thread is None or not log_worker_thread.is_alive():
        log_worker_running = True
        log_worker_thread = threading.Thread(target=log_worker, daemon=True)
        log_worker_thread.start()

def stop_async_logging():
    """停止异步日志系统"""
    global log_worker_running, log_worker_thread
    
    log_worker_running = False
    if log_worker_thread and log_worker_thread.is_alive():
        log_worker_thread.join(timeout=3.0)  # 最多等待3秒

# 创建异步处理器
async_handler = AsyncLogHandler()
async_handler.setLevel(logging.ERROR)

# 添加处理器到日志记录器
logger.addHandler(async_handler)

# 启动异步日志系统
start_async_logging()

# 注册程序退出时的清理函数
atexit.register(stop_async_logging)

# 为了向后兼容，保持原有的logging接口
logging = logger
