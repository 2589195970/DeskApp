#!/usr/bin/env node

/**
 * 构建准备脚本 - 为智多分机考霸屏桌面端准备构建环境
 * 此脚本负责准备 Electron 应用的构建环境，优化轻量化打包
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 开始构建准备过程...');

// 项目根目录
const ROOT_DIR = path.resolve(__dirname, '../..');
const ELECTRON_DIR = path.join(ROOT_DIR, 'Electron_App');
const DIST_DIR = path.join(ROOT_DIR, 'dist');

/**
 * 确保目录存在
 */
function ensureDir(dirPath) {
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
        console.log(`✅ 创建目录: ${dirPath}`);
    }
}

/**
 * 清理构建目录
 */
function cleanBuildDirs() {
    console.log('🧹 清理构建目录...');
    
    const dirsToClean = [
        path.join(ELECTRON_DIR, 'dist_electron'),
        path.join(ROOT_DIR, 'LockSys_Python', 'dist'),
        path.join(ROOT_DIR, 'ChangeConfigUtil', 'dist'),
        DIST_DIR
    ];
    
    dirsToClean.forEach(dir => {
        if (fs.existsSync(dir)) {
            fs.rmSync(dir, { recursive: true, force: true });
            console.log(`🗑️  清理: ${dir}`);
        }
    });
}

/**
 * 构建 Electron 应用
 */
function buildElectronApp() {
    console.log('⚡ 构建 Electron 应用...');
    
    process.chdir(ELECTRON_DIR);
    
    try {
        // 检查当前架构
        const architecture = process.env.GITHUB_MATRIX_ARCHITECTURE || 'x64';
        console.log(`🏗️  构建架构: ${architecture}`);
        
        // 构建 Vue 应用
        console.log('🔧 构建 Vue 应用...');
        execSync('npm run build', { 
            stdio: 'inherit',
            env: {
                ...process.env,
                NODE_OPTIONS: '--openssl-legacy-provider'  // 兼容旧版加密算法
            }
        });
        
        // 构建 Electron 应用
        console.log('📦 构建 Electron 应用...');
        const electronArch = architecture === 'x86' ? 'ia32' : 'x64';
        execSync(`npx electron-builder --win --${electronArch} --dir`, { 
            stdio: 'inherit',
            env: {
                ...process.env,
                ELECTRON_BUILDER_ALLOW_UNRESOLVED_DEPENDENCIES: 'true',
                NODE_OPTIONS: '--openssl-legacy-provider'  // 兼容旧版加密算法
            }
        });
        
        console.log('✅ Electron 应用构建完成');
    } catch (error) {
        console.error('❌ Electron 构建失败:', error.message);
        process.exit(1);
    } finally {
        process.chdir(ROOT_DIR);
    }
}

/**
 * 优化构建文件
 */
function optimizeBuild() {
    console.log('⚡ 优化构建文件...');
    
    const electronDistDir = path.join(ELECTRON_DIR, 'dist_electron');
    
    if (fs.existsSync(electronDistDir)) {
        // 移除不必要的文件以减小体积
        const filesToRemove = [
            'win-unpacked/resources/app.asar.unpacked',
            'win-ia32-unpacked/resources/app.asar.unpacked'
        ];
        
        filesToRemove.forEach(filePattern => {
            const fullPath = path.join(electronDistDir, filePattern);
            if (fs.existsSync(fullPath)) {
                fs.rmSync(fullPath, { recursive: true, force: true });
                console.log(`🗑️  移除优化: ${filePattern}`);
            }
        });
        
        console.log('✅ 构建优化完成');
    }
}

/**
 * 验证构建文件
 */
function validateBuild() {
    console.log('🔍 验证构建文件...');
    
    const architecture = process.env.GITHUB_MATRIX_ARCHITECTURE || 'x64';
    const archSuffix = architecture === 'x86' ? 'ia32' : 'x64';
    
    const expectedPaths = [
        path.join(ELECTRON_DIR, 'dist_electron', `win-${archSuffix}-unpacked`),
        path.join(ROOT_DIR, 'LockSys_Python', 'dist', `win${architecture === 'x64' ? '64' : '32'}`),
        path.join(ROOT_DIR, 'ChangeConfigUtil', 'dist', `win${architecture === 'x64' ? '64' : '32'}`)
    ];
    
    let allValid = true;
    expectedPaths.forEach(expectedPath => {
        if (fs.existsSync(expectedPath)) {
            console.log(`✅ 验证通过: ${expectedPath}`);
        } else {
            console.error(`❌ 缺失文件: ${expectedPath}`);
            allValid = false;
        }
    });
    
    if (!allValid) {
        console.error('❌ 构建验证失败');
        process.exit(1);
    }
    
    console.log('✅ 所有构建文件验证通过');
}

// 主执行流程
function main() {
    try {
        console.log('📋 构建信息:');
        console.log(`   - Node.js: ${process.version}`);
        console.log(`   - 平台: ${process.platform}`);
        console.log(`   - 架构: ${process.env.GITHUB_MATRIX_ARCHITECTURE || 'x64'}`);
        console.log(`   - 工作目录: ${ROOT_DIR}`);
        
        // 创建必要目录
        ensureDir(DIST_DIR);
        ensureDir(path.join(ROOT_DIR, 'installer', 'inno-setup', 'resources'));
        
        // 执行构建准备步骤
        cleanBuildDirs();
        buildElectronApp();
        optimizeBuild();
        validateBuild();
        
        console.log('🎉 构建准备完成！');
        
    } catch (error) {
        console.error('💥 构建准备失败:', error);
        process.exit(1);
    }
}

// 运行主函数
if (require.main === module) {
    main();
}

module.exports = {
    main,
    buildElectronApp,
    optimizeBuild,
    validateBuild
};