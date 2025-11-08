// 预缓存所有依赖和入口文件
console.log('开始预缓存Deno依赖...');

// 预缓存主要入口文件
const mainFiles = [
  'src/index.ts',
  'src/test.ts',
  'src/main.ts', // 如果存在的话
  'src/controllers/cron.ts' // 根据实际结构调整
];

for (const file of mainFiles) {
  try {
    // 使用import()动态导入来触发依赖解析
    const module = await import(`../${file}`);
    console.log(`✓ 预缓存: ${file}`);
  } catch (error) {
    console.log(`⚠ 跳过 ${file}: ${error.message}`);
  }
}

console.log('依赖预缓存完成！');
