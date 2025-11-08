# 使用多架构支持的Deno镜像
FROM --platform=$BUILDPLATFORM denoland/deno:alpine-2.0.0

WORKDIR /app

# 1. 复制配置文件（利用Docker缓存层）
COPY deno.json deno.lock ./

# 2. 复制源码目录结构
COPY src/ ./src/
COPY templates/ ./templates/
COPY scripts/ ./scripts/

# 3. 预缓存所有依赖（关键步骤）
RUN echo "开始安装JSR和npm依赖..." && \
    # 预缓存主要入口文件来触发依赖下载
    deno cache src/index.ts && \
    deno cache src/test.ts && \
    # 尝试缓存可能的其他入口点
    [ -f "src/main.ts" ] && deno cache src/main.ts || echo "src/main.ts不存在，跳过" && \
    [ -f "src/controllers/cron.ts" ] && deno cache src/controllers/cron.ts || echo "cron.ts不存在，跳过" && \
    # 运行预缓存脚本
    deno run -A scripts/precache.js && \
    # 清理缓存以减少镜像大小
    deno info --json > /dev/null && \
    echo "所有依赖预缓存完成！"

# 4. 创建非root用户
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# 5. 暴露端口
EXPOSE 3000

# 6. 启动命令（所有依赖已预下载）
CMD ["deno", "task", "start"]
