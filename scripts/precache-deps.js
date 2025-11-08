// 预加载所有需要的依赖模块
import { dependencies } from '../deno.json' assert { type: 'json' };

console.log('Pre-caching Deno dependencies...');

// 这里可以列出所有需要预缓存的入口文件
const entryPoints = [
  'src/main.ts',
  'src/controllers/cron.ts',
  'src/modules/wechat/publisher.ts',
  'src/modules/ai/summarizer.ts',
  // 添加其他主要入口文件
];

for (const file of entryPoints) {
  try {
    await import(`../${file}`);
    console.log(`✓ Pre-cached: ${file}`);
  } catch (error) {
    console.log(`⚠ Could not cache ${file}: ${error.message}`);
  }
}

console.log('Dependency pre-caching completed!');
