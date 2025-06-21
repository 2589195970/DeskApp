#!/usr/bin/env node
/**
 * UniversityMarking 系统构建准备脚本
 * 用于在执行安装程序构建之前准备所需的文件和目录
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 项目根目录
const projectRoot = path.join(__dirname, '../..');

// 目标目录配置
const buildDirs = {
  electronApp: path.join(projectRoot, 'Electron_App/dist'),
  pythonService: path.join(projectRoot, 'LockSys_Python/dist'),
  configTool: path.join(projectRoot, 'ChangeConfigUtil/dist'),
  installer: path.join(projectRoot, 'installer'),
  output: path.join(projectRoot, 'dist')
};

function log(message) {
  console.log(`[PREPARE-BUILD] ${message}`);
}

function ensureDirectory(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
    log(`Created directory: ${dirPath}`);
  }
}

function checkRequiredFiles() {
  log('Checking required files...');
  
  const requiredFiles = [
    path.join(projectRoot, 'Electron_App/package.json'),
    path.join(projectRoot, 'LockSys_Python/main.py'),
    path.join(projectRoot, 'ChangeConfigUtil/main.py'),
    path.join(projectRoot, 'Start_Bat/start.bat')
  ];
  
  let allFilesExist = true;
  
  requiredFiles.forEach(file => {
    if (!fs.existsSync(file)) {
      console.error(`❌ Missing required file: ${file}`);
      allFilesExist = false;
    } else {
      log(`✅ Found: ${file}`);
    }
  });
  
  if (!allFilesExist) {
    console.error('❌ Some required files are missing. Please check the project structure.');
    process.exit(1);
  }
  
  log('✅ All required files are present.');
}

function buildElectronApp() {
  log('Building Electron application...');
  
  const electronDir = path.join(projectRoot, 'Electron_App');
  
  try {
    // 检查是否已安装依赖
    if (!fs.existsSync(path.join(electronDir, 'node_modules'))) {
      log('Installing npm dependencies...');
      execSync('npm install', { cwd: electronDir, stdio: 'inherit' });
    }
    
    // 构建 Electron 应用
    log('Running Electron build...');
    execSync('npm run build', { cwd: electronDir, stdio: 'inherit' });
    
    // 如果有 electron:build 命令，也执行它
    try {
      execSync('npm run electron:build', { cwd: electronDir, stdio: 'inherit' });
    } catch (e) {
      log('electron:build not available, using regular build');
    }
    
    log('✅ Electron application built successfully.');
  } catch (error) {
    console.error('❌ Failed to build Electron application:', error.message);
    process.exit(1);
  }
}

function buildPythonComponents() {
  log('Building Python components...');
  
  const pythonDirs = [
    { name: 'LockSys_Python', path: path.join(projectRoot, 'LockSys_Python') },
    { name: 'ChangeConfigUtil', path: path.join(projectRoot, 'ChangeConfigUtil') }
  ];
  
  pythonDirs.forEach(({ name, path: componentPath }) => {
    try {
      log(`Building ${name}...`);
      
      const distPath = path.join(componentPath, 'dist');
      const specFile = path.join(componentPath, 'main.spec');
      
      // 清理之前的构建
      if (fs.existsSync(distPath)) {
        fs.rmSync(distPath, { recursive: true, force: true });
      }
      
      // 使用 PyInstaller 构建
      if (fs.existsSync(specFile)) {
        execSync(`pyinstaller main.spec`, { cwd: componentPath, stdio: 'inherit' });
      } else {
        execSync(`pyinstaller --onefile main.py`, { cwd: componentPath, stdio: 'inherit' });
      }
      
      log(`✅ ${name} built successfully.`);
    } catch (error) {
      console.error(`❌ Failed to build ${name}:`, error.message);
      process.exit(1);
    }
  });
}

function copyStaticFiles() {
  log('Copying static files...');
  
  const staticFiles = [
    {
      src: path.join(projectRoot, 'Start_Bat/start.bat'),
      dest: path.join(buildDirs.installer, 'static/start.bat')
    },
    {
      src: path.join(projectRoot, 'README.md'),
      dest: path.join(buildDirs.installer, 'static/README.md')
    }
  ];
  
  staticFiles.forEach(({ src, dest }) => {
    if (fs.existsSync(src)) {
      ensureDirectory(path.dirname(dest));
      fs.copyFileSync(src, dest);
      log(`✅ Copied: ${src} -> ${dest}`);
    } else {
      log(`⚠️ Static file not found: ${src}`);
    }
  });
}

function generateBuildInfo() {
  log('Generating build information...');
  
  const buildInfo = {
    buildTime: new Date().toISOString(),
    version: '1.0.0',
    components: {
      electronApp: fs.existsSync(buildDirs.electronApp),
      pythonService: fs.existsSync(buildDirs.pythonService),
      configTool: fs.existsSync(buildDirs.configTool)
    }
  };
  
  const buildInfoPath = path.join(buildDirs.installer, 'build-info.json');
  fs.writeFileSync(buildInfoPath, JSON.stringify(buildInfo, null, 2));
  
  log('✅ Build information generated.');
  log(`Build info saved to: ${buildInfoPath}`);
}

function main() {
  log('Starting build preparation...');
  
  // 确保必要的目录存在
  Object.values(buildDirs).forEach(ensureDirectory);
  
  // 执行构建准备步骤
  checkRequiredFiles();
  buildElectronApp();
  buildPythonComponents();
  copyStaticFiles();
  generateBuildInfo();
  
  log('✅ Build preparation completed successfully!');
  log('Ready to run Inno Setup compiler.');
}

// 如果直接运行此脚本
if (require.main === module) {
  main();
}

module.exports = {
  main,
  buildElectronApp,
  buildPythonComponents,
  copyStaticFiles,
  generateBuildInfo
};