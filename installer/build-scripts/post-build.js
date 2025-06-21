#!/usr/bin/env node
/**
 * UniversityMarking 系统构建后处理脚本
 * 用于在安装程序构建完成后执行清理和验证任务
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// 项目根目录
const projectRoot = path.join(__dirname, '../..');

function log(message) {
  console.log(`[POST-BUILD] ${message}`);
}

function calculateFileHash(filePath) {
  if (!fs.existsSync(filePath)) {
    return null;
  }
  
  const fileBuffer = fs.readFileSync(filePath);
  const hashSum = crypto.createHash('sha256');
  hashSum.update(fileBuffer);
  return hashSum.digest('hex');
}

function getFileSize(filePath) {
  if (!fs.existsSync(filePath)) {
    return 0;
  }
  
  const stats = fs.statSync(filePath);
  return stats.size;
}

function formatFileSize(bytes) {
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  if (bytes === 0) return '0 Bytes';
  
  const i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
  return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
}

function verifyInstaller() {
  log('Verifying installer package...');
  
  const architecture = process.env.GITHUB_MATRIX_ARCHITECTURE || 'x64';
  const installerPath = path.join(projectRoot, `dist/UniversityMarking-Setup-${architecture}.exe`);
  
  if (!fs.existsSync(installerPath)) {
    console.error('❌ Installer not found at expected location:', installerPath);
    return false;
  }
  
  const fileSize = getFileSize(installerPath);
  const fileHash = calculateFileHash(installerPath);
  
  log(`✅ Installer found: ${installerPath}`);
  log(`File size: ${formatFileSize(fileSize)}`);
  log(`SHA256: ${fileHash}`);
  
  // 检查文件大小是否合理
  const sizeInMB = fileSize / (1024 * 1024);
  if (sizeInMB < 20) {
    console.error('❌ Installer file size seems too small. Possible build error.');
    return false;
  } else if (sizeInMB < 50) {
    console.warn('⚠️  Installer size is smaller than expected (missing Chromium?)');
  } else if (sizeInMB > 300) {
    console.warn('⚠️  Installer size is larger than expected');
  } else {
    log(`✅ Installer size is within expected range: ${formatFileSize(fileSize)}`);
  }
  
  return true;
}

function generateReleaseNotes() {
  log('Generating release notes...');
  
  const buildInfoPath = path.join(projectRoot, 'installer/build-info.json');
  
  if (!fs.existsSync(buildInfoPath)) {
    log('⚠️ Build info not found, skipping release notes generation.');
    return;
  }
  
  const buildInfo = JSON.parse(fs.readFileSync(buildInfoPath, 'utf8'));
  const architecture = process.env.GITHUB_MATRIX_ARCHITECTURE || 'x64';
  const installerPath = path.join(projectRoot, `dist/UniversityMarking-Setup-${architecture}.exe`);
  
  const releaseNotes = `# 智多分机考霸屏桌面端 v${buildInfo.version} (${architecture})

## 构建信息
- 构建时间: ${buildInfo.buildTime}
- 安装程序大小: ${formatFileSize(getFileSize(installerPath))}
- SHA256: ${calculateFileHash(installerPath)}

## 组件状态
- Electron 主程序: ${buildInfo.components.electronApp ? '✅' : '❌'}
- Python 系统锁定服务: ${buildInfo.components.pythonService ? '✅' : '❌'}
- 配置工具: ${buildInfo.components.configTool ? '✅' : '❌'}

## 安装说明
1. 以管理员身份运行安装程序
2. 选择安装目录和组件
3. 安装完成后使用桌面快捷方式启动

## 系统要求
- Windows 7 SP1 或更高版本 (${architecture === 'x86' ? '32位' : '64位'})
- 管理员权限 (必需)
- 至少 2GB 内存 (支持 1C 2GB 低配置)
- 至少 200MB 可用磁盘空间

## 使用注意事项
- 专为考试监考环境设计，支持系统级锁定
- 请在安装前关闭杀毒软件的实时监控
- 如遇到安装问题，请以管理员身份重新运行
- 系统锁定功能需要管理员权限才能正常工作
- 支持虚拟化环境下的 Win7 SP1 部署
`;
  
  const releaseNotesPath = path.join(projectRoot, 'dist/RELEASE-NOTES.md');
  fs.writeFileSync(releaseNotesPath, releaseNotes);
  
  log(`✅ Release notes generated: ${releaseNotesPath}`);
}

function cleanupBuildFiles() {
  log('Cleaning up temporary build files...');
  
  const tempDirs = [
    path.join(projectRoot, 'Electron_App/dist'),
    path.join(projectRoot, 'LockSys_Python/build'),
    path.join(projectRoot, 'ChangeConfigUtil/build'),
    path.join(projectRoot, 'installer/static')
  ];
  
  tempDirs.forEach(dir => {
    if (fs.existsSync(dir)) {
      try {
        fs.rmSync(dir, { recursive: true, force: true });
        log(`✅ Cleaned: ${dir}`);
      } catch (error) {
        log(`⚠️ Failed to clean ${dir}: ${error.message}`);
      }
    }
  });
}

function createDistributionPackage() {
  log('Creating distribution package...');
  
  const distDir = path.join(projectRoot, 'dist');
  const packageInfo = {
    name: 'UniversityMarking',
    version: '1.0.0',
    description: '大学考试监考系统',
    files: []
  };
  
  // 扫描 dist 目录中的文件
  if (fs.existsSync(distDir)) {
    const files = fs.readdirSync(distDir);
    files.forEach(file => {
      const filePath = path.join(distDir, file);
      const stats = fs.statSync(filePath);
      
      if (stats.isFile()) {
        packageInfo.files.push({
          name: file,
          size: formatFileSize(stats.size),
          hash: calculateFileHash(filePath),
          modified: stats.mtime.toISOString()
        });
      }
    });
  }
  
  const packageInfoPath = path.join(distDir, 'package-info.json');
  fs.writeFileSync(packageInfoPath, JSON.stringify(packageInfo, null, 2));
  
  log(`✅ Distribution package info created: ${packageInfoPath}`);
}

function main() {
  log('Starting post-build processing...');
  
  const success = verifyInstaller();
  
  if (!success) {
    console.error('❌ Post-build verification failed!');
    process.exit(1);
  }
  
  generateReleaseNotes();
  createDistributionPackage();
  cleanupBuildFiles();
  
  log('✅ Post-build processing completed successfully!');
  log('\n=== BUILD SUMMARY ===');
  log('Installer: dist/UniversityMarking-Setup.exe');
  log('Release Notes: dist/RELEASE-NOTES.md');
  log('Package Info: dist/package-info.json');
  log('==================\n');
}

// 如果直接运行此脚本
if (require.main === module) {
  main();
}

module.exports = {
  main,
  verifyInstaller,
  generateReleaseNotes,
  cleanupBuildFiles,
  createDistributionPackage
};